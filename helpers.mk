ifndef V
.SILENT:
MAKEFLAGS += --no-print-directory
Q         := @
endif

empty :=
space := $(empty) $(empty)

define newline
$(empty)
$(empty)
endef

define toupper
$(shell echo '$(1)' | tr '[:lower:]' '[:upper:]')
endef

define rm_recipe
@echo "  RM      $(1)"
$(Q)$(RM) $(1)
endef

define rmr_recipe
@echo "  RMR     $(1)"
$(Q)$(RM) -r $(1)
endef

define ln_recipe
@echo "  LN      $(2)"
$(Q)$(LN) -s $(1) $(2)
endef

define kconf_enabled
$(if $(filter __y__,__$(subst $(space),,$(strip $(CONFIG_$(1))))__),$(2))
endef

define pkgconfig_cmd
$(shell env PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" $(PKG_CONFIG) $(1))
endef

define pkgconfig_cflags
$(if $(1),$(call pkgconfig_cmd,--cflags $(1)))
endef

define pkgconfig_ldflags
$(if $(1),$(call pkgconfig_cmd,--libs $(1)))
endef

# $(1): prerequisite object pathname
# $(2): final object pathname
define obj_cflags
$(strip $(if $($(subst $(BUILDDIR)/,,$(1))-cflags), \
             $($(subst $(BUILDDIR)/,,$(1))-cflags), \
             $($(2)-cflags)) \
             $(call pkgconfig_cflags,$($(2)-pkgconf)))
endef

define link_ldflags
$(strip $($(1)-ldflags) $(call pkgconfig_ldflags,$($(1)-pkgconf)))
endef

define obj_includes
$(strip $(if $(kconf_head),-I$(abspath $(kconf_head)/../..)) \
        -I$(dir $(1)) \
        -I$(dir $(2)) \
        $(if $(HEADERDIR),-I$(HEADERDIR)))
endef

define clean_recipe
$(foreach l, \
          $(1), \
          $(foreach o, \
                    $($(l)-objs) \
                    $(patsubst %.o,%.d,$($(l)-objs)) \
                    $(patsubst %.o,%.gcno,$($(l)-objs)) \
                    $(patsubst %.o,%.gcda,$($(l)-objs)), \
                    $(call rm_recipe,$(BUILDDIR)/$(o))$(newline)) \
          $(call rm_recipe,$(BUILDDIR)/$(l))$(newline))
endef

define strip_lib_recipe
@echo "  STRIP   $(1)"
$(Q)$(STRIP) --strip-unneeded $(1)
endef

define strip_bin_recipe
@echo "  STRIP   $(1)"
$(Q)$(STRIP) --strip-all $(1)
endef

define install_recipe
@echo "  INSTALL $(3)"
$(Q)mkdir -p -m755 $(dir $(3))
$(Q)$(INSTALL) $(1) $(2) $(3)
endef

define uninstall_recipe
$(foreach f,$(addprefix $(1)/,$(2)),$(call rm_recipe,$(f))$(newline))
endef

.DEFAULT_GOAL := build

.SUFFIXES:
