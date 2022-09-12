ifeq ($(realpath $(EBUILDDIR)),)
$(error Missing EBUILDDIR definition !)
endif
export EBUILDDIR

ifeq ($(strip $(PACKAGE)),)
$(error Missing PACKAGE definition !)
endif
export PACKAGE

export CROSS_COMPILE :=
export DESTDIR       :=
export PREFIX        := /usr/local
export SYSCONFDIR    := $(abspath $(PREFIX)/etc)
export INCLUDEDIR    := $(abspath $(PREFIX)/include)
export BINDIR        := $(abspath $(PREFIX)/bin)
export SBINDIR       := $(abspath $(PREFIX)/sbin)
export LIBDIR        := $(abspath $(PREFIX)/lib)
export LIBEXECDIR    := $(abspath $(PREFIX)/libexec)
export PKGCONFIGDIR  := $(abspath $(LIBDIR)/pkgconfig)
export LOCALSTATEDIR := $(abspath $(PREFIX)/var)
export RUNSTATEDIR   := $(abspath $(PREFIX)/run)

export CC            := $(CROSS_COMPILE)gcc
export AR            := $(CROSS_COMPILE)gcc-ar
export LD            := $(CROSS_COMPILE)gcc
export STRIP         := $(CROSS_COMPILE)strip
export RM            := rm -f
export LN            := ln -f
export PKG_CONFIG    := pkg-config
export INSTALL       := install
export KCONF         := kconfig-conf
export KMCONF        := kconfig-mconf
export KXCONF        := kconfig-qconf
export KGCONF        := kconfig-gconf
export KNCONF        := kconfig-nconf

export TOPDIR        := $(CURDIR)

DEFCONFIG            :=
SRCDIR               := $(CURDIR)
HEADERDIR            := $(CURDIR)
BUILDDIR             := $(CURDIR)/build

ebuild_mkfile := $(CURDIR)/ebuild.mk
ebuild_deps   := $(ebuild_mkfile) \
                 $(EBUILDDIR)/main.mk \
                 $(EBUILDDIR)/helpers.mk \
                 $(EBUILDDIR)/rules.mk

# If existing, load configuration early in the process so that project's
# ebuild.mk may access kconfig make definitions (if any).
__kconf_autoconf_path := $(BUILDDIR)/auto.conf
-include $(__kconf_autoconf_path)

include $(EBUILDDIR)/helpers.mk
include $(CURDIR)/ebuild.mk

################################################################################
# Config handling
################################################################################

kconf_config := $(BUILDDIR)/.config

ifdef config-in

kconf_head   := $(BUILDDIR)/include/$(PACKAGE)/config.h
all_deps     := $(kconf_head)

config-in    := $(CURDIR)/$(config-in)
ifeq ($(wildcard $(config-in)),)
$(error '$(config-in)' configuration template file not found !)
endif

kconfdir       := $(BUILDDIR)/include/config/
kconf_autoconf := $(__kconf_autoconf_path)
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

$(ebuild_mkfile): $(kconf_autoconf)

$(kconf_autoconf): $(kconf_config)
	@:

.PHONY: config
config: $(kconf_config)

$(kconf_config): $(config-in) \
                 | $(kconfdir)
	@echo "  KCONF   $(@)"
	$(Q)$(call kconf_sync_cmd,olddefconfig)
	$(Q)$(kconf_regen_cmd)

.PHONY: olddefconfig
olddefconfig: $(config-in) \
              | $(kconfdir)
	@echo "  KCONF   $(kconf_config)"
	$(Q)$(call kconf_sync_cmd,olddefconfig)
	$(Q)$(kconf_regen_cmd)

$(kconf_autohead): | $(kconfdir)
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

ifneq ($(strip $(DEFCONFIG)),)
.PHONY: defconfig
defconfig: | $(kconfdir)
	$(Q)cp $(DEFCONFIG) $(kconf_config)
	$(Q)$(call kconf_sync_cmd,olddefconfig)
	$(Q)$(kconf_regen_cmd)
else
.PHONY: defconfig
defconfig: | $(kconfdir)
	$(Q)$(call kconf_sync_cmd,alldefconfig)
	$(Q)$(kconf_regen_cmd)
endif

saveconfig: $(kconf_config)
	$(Q)if [ ! -f "$(<)" ]; then \
		echo "  KCONF   $(<)"; \
		$(call kconf_sync_cmd,olddefconfig); \
		$(kconf_regen_cmd); \
	    fi
	@echo "  KSAVE   $(BUILDDIR)/defconfig"
	$(call kconf_sync_cmd,savedefconfig $(BUILDDIR)/defconfig)

else  # ifndef config-in

all_deps := $(ebuild_deps)

.PHONY: config
config menuconfig xconfig gconfig nconfig defconfig saveconfig:
	$(error Missing configuration template definition !)

endif # config-in

include $(EBUILDDIR)/rules.mk

################################################################################
# Distclean handling
################################################################################

.PHONY: distclean
distclean: clean
ifdef config-in
	$(call rmr_recipe,$(kconfdir))
	$(call rm_recipe,$(kconf_autoconf))
	$(call rm_recipe,$(kconf_autohead))
	$(call rm_recipe,$(kconf_head))
	$(call rm_recipe,$(kconf_config))
	$(call rm_recipe,$(kconf_config).old)
	$(call rm_recipe,$(BUILDDIR)/defconfig)
endif # config-in
