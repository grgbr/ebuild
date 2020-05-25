ebuild_mkfile        := $(lastword $(MAKEFILE_LIST))
all_deps             := $(subst $(ebuild_mkfile),,$(MAKEFILE_LIST))

export DESTDIR       :=
export PREFIX        := /usr/local
export INCLUDEDIR    := $(abspath $(PREFIX)/include)
export BINDIR        := $(abspath $(PREFIX)/bin)
export LIBDIR        := $(abspath $(PREFIX)/lib)
export PKGCONFIGDIR  := $(abspath $(LIBDIR)/pkgconfig)
export LOCALSTATEDIR := $(abspath $(PREFIX)/var)

export CC            := gcc
export AR            := gcc-ar
export LD            := gcc
export STRIP         := strip
export RM            := rm -f
export PKG_CONFIG    := pkg-config
export INSTALL       := install
export KCONF         := kconfig-conf
export KMCONF        := kconfig-mconf
export KXCONF        := kconfig-qconf
export KGCONF        := kconfig-gconf
export KNCONF        := kconfig-nconf

export TOPDIR        := $(CURDIR)

SRCDIR               := $(CURDIR)
HEADERDIR            := $(CURDIR)
BUILDDIR             := $(CURDIR)/build

include $(EBUILDDIR)/helpers.mk

################################################################################
# Config handling
################################################################################

kconf_config := $(BUILDDIR)/.config
kconf_head   := $(BUILDDIR)/include/$(PACKAGE)/config.h

ifdef config-in

config-in := $(CURDIR)/$(config-in)
ifeq ($(wildcard $(config-in)),)
$(error '$(config-in)' configuration template file not found !)
endif

kconfdir       := $(BUILDDIR)/include/config/
kconf_autoconf := $(BUILDDIR)/auto.conf
kconf_autohead := $(BUILDDIR)/autoconf.h

define kconf_cmd
cd $(BUILDDIR) && \
KCONFIG_AUTOCONFIG=$(kconf_autoconf) \
KCONFIG_AUTOHEADER=$(kconf_autohead) \
$(1)
endef

define kconf_sync_cmd
$(call kconf_cmd,$(KCONF)) --$(1) $(config-in) >/dev/null
endef

define kconf_regen_cmd
$(call kconf_cmd,$(KCONF)) --silentoldconfig $(config-in)
endef

define kconf_runui_recipe
$(Q)$(call kconf_cmd,$(1)) $(config-in)
$(Q)$(call kconf_cmd,$(KCONF)) --silentoldconfig $(config-in)
endef

$(EBUILDDIR)/ebuild.mk: $(kconf_autoconf)

$(kconf_autoconf): $(kconf_config)
	@:

-include $(kconf_autoconf)

.PHONY: config
config: $(kconf_config)

$(kconf_config): $(config-in) $(all_deps) | $(kconfdir)
	@echo "KCONF     $(@)"
	$(Q)$(call kconf_sync_cmd,olddefconfig)
	$(Q)$(kconf_regen_cmd)

$(kconf_autohead): $(kconf_config)
	@:

$(kconf_head): $(kconf_autohead) | $(dir $(kconf_head))
	$(Q):; > $(@); \
	    exec >> $(@); \
	    echo '#ifndef _$(call toupper,$(PACKAGE))_CONFIG_H'; \
	    echo '#define _$(call toupper,$(PACKAGE))_CONFIG_H'; \
	    echo; \
	    grep '^#define' $(<); \
	    echo; \
	    echo '#endif /* _$(call toupper,$(PACKAGE))_CONFIG_H */'

.PHONY: menuconfig
menuconfig: | $(kconfdir)
	$(call kconf_runui_recipe,$(KMCONF))

.PHONY: xconfig
xconfig: | $(kconfdir)
	$(call kconf_runui_recipe,$(KXCONF))

.PHONY: gconfig
gconfig: | $(kconfdir)
	$(call kconf_runui_recipe,$(KGCONF))

.PHONY: nconfig
nconfig: | $(kconfdir)
	$(call kconf_runui_recipe,$(KNCONF))

.PHONY: defconfig
defconfig: | $(kconfdir)
	$(Q)$(call kconf_sync_cmd,alldefconfig)
	$(Q)$(kconf_regen_cmd)

saveconfig: $(kconf_config)
	$(Q)if [ ! -f "$(<)" ]; then \
		echo "KCONF     $(<)"; \
		$(call kconf_sync_cmd,olddefconfig); \
		$(kconf_regen_cmd); \
	    fi
	@echo "KSAVECONF $(BUILDDIR)/defconfig"
	$(call kconf_sync_cmd,savedefconfig $(BUILDDIR)/defconfig)

else  # ifndef config-in

.PHONY: config
config menuconfig xconfig gconfig nconfig defconfig saveconfig:
	$(error Missing configuration template definition !)

$(kconf_config): $(all_deps) | $(BUILDDIR)
	@touch $(@)

$(kconf_head): $(dir $(kconf_head))
	@touch $(@)

endif # config-in

################################################################################
# Build handling
################################################################################

# $(1): prerequisite object pathname
# $(2): final object pathname
define gen_obj_rule
$(BUILDDIR)/$(1): $(SRCDIR)/$(patsubst %.o,%.c,$(notdir $(1))) \
                  $(kconf_head) $(ebuild_mkfile) \
                  | $(dir $(BUILDDIR)/$(1))
	@echo "CC        $$(@)"
	$(Q)$(CC) -I$$(call obj_includes,$$(@),$$(<)) \
	          -MD -g $(call obj_cflags,$(1),$(2)) -o $$(@) -c $$(<)
endef

define gen_arlib_rule
$(BUILDDIR)/$(1): $(addprefix $(BUILDDIR)/,$($(1)-objs))
	$(if $($(1)-objs),,$$(error Missing '$(1)' build objects declaration !))
	@echo "AR        $$(@)"
	$(Q)$(AR) rcs $$(@) $$(^)

$(foreach o,$($(1)-objs),$(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_solib_rule
$(BUILDDIR)/$(1): $(addprefix $(BUILDDIR)/,$($(1)-objs))
	$(if $($(1)-objs),,$$(error Missing '$(1)' build objects declaration !))
	@echo "LD        $$(@)"
	$(Q)$(LD) -o $$(@) $$(^) -L$(BUILDDIR) $(call link_ldflags,$(1))

$(foreach o,$($(1)-objs),$(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_pkgconfig_rule
$(BUILDDIR)/$(1): $(kconf_config) $(ebuild_mkfile) \
                  | $(BUILDDIR)
	$(if $($(1)-tmpl), \
	     , \
	     $$(error Missing '$(1)' pkgconfig template declaration !))
	@echo "PKGCFG    $$(@)"
	$(Q)/bin/echo -e '$$(subst $$(newline),\n,$$($($(1)-tmpl)))' > $$(@)
endef

define gen_bin_rule
$(BUILDDIR)/$(1): $(addprefix $(BUILDDIR)/,$($(1)-objs)) \
                  $(addprefix $(BUILDDIR)/,$(solibs)) \
                  $(addprefix $(BUILDDIR)/,$(arlibs))
	@echo "LD        $$(@)"
	$(Q)$(LD) -o $$(@) $$(^) -L$(BUILDDIR) $(call link_ldflags,$(1))

$(foreach o,$($(1)-objs),$(call gen_obj_rule,$(o),$(1))$(newline))
endef

kconf_subdir_args := kconf_autoconf:="$(kconf_autoconf)" \
                     kconf_head:="$(kconf_head)"

define gen_subdir_rule
.PHONY: build-$(1)
build-$(1): $(addprefix build-,$($(1)-deps)) $(kconf_head)
	$(Q)$(MAKE) --directory $(CURDIR)/$(1) \
	            --makefile $(EBUILDDIR)/subdir.mk \
	            build \
	            EBUILDDIR:="$(EBUILDDIR)" \
	            PACKAGE:="$(PACKAGE)" \
	            BUILDDIR:="$(BUILDDIR)/$(1)" \
	            $(kconf_subdir_args)

.PHONY: clean-$(1)
clean-$(1):
	$(Q)$(MAKE) --directory $(CURDIR)/$(1) \
	            --makefile $(EBUILDDIR)/subdir.mk \
	            clean \
	            EBUILDDIR:="$(EBUILDDIR)" \
	            PACKAGE:="$(PACKAGE)" \
	            BUILDDIR:=$(BUILDDIR)/$(1) \
	            $(kconf_subdir_args)

.PHONY: install-$(1)
install-$(1): $(addprefix install-,$($(1)-deps)) $(kconf_head)
	$(Q)$(MAKE) --directory $(CURDIR)/$(1) \
	            --makefile $(EBUILDDIR)/subdir.mk \
	            install \
	            EBUILDDIR:="$(EBUILDDIR)" \
	            PACKAGE:="$(PACKAGE)" \
	            BUILDDIR:=$(BUILDDIR)/$(1) \
	            $(kconf_subdir_args)

.PHONY: uninstall-$(1)
uninstall-$(1): $(addprefix uninstall-,$($(1)-deps))
	$(Q)$(MAKE) --directory $(CURDIR)/$(1) \
	            --makefile $(EBUILDDIR)/subdir.mk \
	            uninstall \
	            EBUILDDIR:="$(EBUILDDIR)" \
	            PACKAGE:="$(PACKAGE)" \
	            BUILDDIR:=$(BUILDDIR)/$(1) \
	            $(kconf_subdir_args)
endef

.PHONY: build
build: $(addprefix build-,$(subdirs)) \
       $(addprefix $(BUILDDIR)/,$(arlibs)) \
       $(addprefix $(BUILDDIR)/,$(solibs)) \
       $(addprefix $(BUILDDIR)/,$(pkgconfigs)) \
       $(addprefix $(BUILDDIR)/,$(bins))

$(eval $(foreach d,$(subdirs),$(call gen_subdir_rule,$(d))$(newline)))

$(eval $(foreach l,$(arlibs),$(call gen_arlib_rule,$(l))$(newline)))

$(eval $(foreach l,$(solibs),$(call gen_solib_rule,$(l))$(newline)))

$(eval $(foreach p,$(pkgconfigs),$(call gen_pkgconfig_rule,$(p))$(newline)))

$(eval $(foreach b,$(bins),$(call gen_bin_rule,$(b))$(newline)))

################################################################################
# Clean handling
################################################################################

.PHONY: clean
clean: $(addprefix clean-,$(subdirs))
	$(call clean_recipe,$(arlibs) $(solibs) $(pkgconfigs) $(bins))

################################################################################
# Distclean handling
################################################################################

.PHONY: distclean
distclean: clean
	$(call rmr_recipe,$(kconfdir))
	$(call rm_recipe,$(kconf_autoconf))
	$(call rm_recipe,$(kconf_autohead))
	$(call rm_recipe,$(kconf_head))
	$(call rm_recipe,$(kconf_config))
	$(call rm_recipe,$(kconf_config).old)
	$(call rm_recipe,$(BUILDDIR)/defconfig)

################################################################################
# Install handling
################################################################################

.PHONY: install
install: $(addprefix install-,$(subdirs)) \
         $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)) \
         $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h)) \
         $(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)) \
         $(addprefix $(DESTDIR)$(LIBDIR)/,$(solibs)) \
         $(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs)) \
         $(addprefix $(DESTDIR)$(BINDIR)/,$(bins))

$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)): \
	$(DESTDIR)$(INCLUDEDIR)/%: $(HEADERDIR)/% $(kconf_config)
	$(call install_recipe,-m644,$(<),$(@))

$(DESTDIR)$(INCLUDEDIR)/$(config-h): $(kconf_head)
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)): \
	$(DESTDIR)$(LIBDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(LIBDIR)/,$(solibs)): \
	$(DESTDIR)$(LIBDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m755,$(<),$(@))

$(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs)): \
	$(DESTDIR)$(PKGCONFIGDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(BINDIR)/,$(bins)): \
	$(DESTDIR)$(BINDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m755,$(<),$(@))

.PHONY: install-strip
install-strip: install
	$(foreach l, \
	          $(addprefix $(DESTDIR)$(LIBDIR)/,$(solibs)), \
	          $(call strip_lib_recipe,$(l))$(newline))
	$(foreach b, \
	          $(addprefix $(DESTDIR)$(BINDIR)/,$(bins)), \
	          $(call strip_bin_recipe,$(b))$(newline))

################################################################################
# Uninstall handling
################################################################################

.PHONY: uninstall
uninstall: $(addprefix uninstall-,$(subdirs))
	$(call uninstall_recipe,$(DESTDIR)$(INCLUDEDIR),$(headers) $(config-h))
	$(call uninstall_recipe,$(DESTDIR)$(LIBDIR),$(arlibs))
	$(call uninstall_recipe,$(DESTDIR)$(LIBDIR),$(solibs))
	$(call uninstall_recipe,$(DESTDIR)$(PKGCONFIGDIR),$(pkgconfigs))
	$(call uninstall_recipe,$(DESTDIR)$(BINDIR),$(bins))

$(BUILDDIR)/ $(dir $(kconf_head)):
	@mkdir -p $(@)

$(BUILDDIR)/%/:
	@mkdir -p $(@)

-include $(wildcard $(BUILDDIR)/*.d)
