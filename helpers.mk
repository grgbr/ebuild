################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

ifndef V
.SILENT:
MAKEFLAGS += --no-print-directory
Q         := @
endif

empty  :=
space  := $(empty) $(empty)
squote := '

define newline :=
$(empty)
$(empty)
endef

# Escape message given in argument for echo'ing to the console
# $(1): (unescaped) message to print
#
# Message will be escaped as required for echo'ing to the console according to
# bash(1) single quoted string escaping rules.
# See bash(1) "QUOTING" section.
define escape_shell_string
$(subst $(squote),\$(squote),$(1))
endef

# Print multi-line message given in argument to the console
# $(1): (unescaped) message to print
#
# Message will be escaped as required for echo'ing to the console.
# Recipes calling this macro MUST run a shell that understands bash(1) single
# quoted string escaping rules.
# See macro escape_shell_string().
define echo_multi_line
$(ECHOE) $$'$(subst $(newline),\n,$(call escape_shell_string,$(1)))'
endef

define toupper
$(shell echo '$(1)' | tr '[:lower:]' '[:upper:]')
endef

define rm_recipe
@echo "  RM      $(strip $(1))"
$(Q)$(RM) $(1)
endef

define rmr_recipe
@echo "  RMR     $(strip $(1))"
$(Q)$(RM) -r $(1)
endef

define ln_recipe
@echo "  LN      $(strip $(2))"
$(Q)$(LN) -s $(1) $(2)
endef

define kconf_is_enabled
$(strip $(filter __y__,__$(subst $(space),,$(strip $(CONFIG_$(strip $(1)))))__))
endef

define kconf_enabled
$(strip $(if $(call kconf_is_enabled,$(1)),$(strip $(2)),$(strip $(3))))
endef

define kconf_disabled
$(strip $(if $(call kconf_is_enabled,$(1)),$(strip $(3)),$(strip $(2))))
endef

define pkgconfig_cmd
$(shell env PKG_CONFIG_LIBDIR="$(PKG_CONFIG_LIBDIR)" \
            PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
            PKG_CONFIG_SYSROOT_DIR="$(PKG_CONFIG_SYSROOT_DIR)" \
            $(PKG_CONFIG) $(1))
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

define strip_solib_recipe
@echo "  STRIP   $(strip $(1))"
$(Q)$(STRIP) --strip-unneeded $(1)
endef

define strip_bin_recipe
@echo "  STRIP   $(strip $(1))"
$(Q)$(STRIP) --strip-all $(1)
endef

define install_recipe
@echo "  INSTALL $(strip $(3))"
$(Q)mkdir -p -m755 $(dir $(3))
$(Q)$(INSTALL) $(1) $(2) $(3)
endef

define uninstall_recipe
$(foreach f,$(addprefix $(1)/,$(2)),$(call rm_recipe,$(f))$(newline))
endef

define installdir_recipe
@echo "  INSTALL $(strip $(3))"
$(Q)mkdir -p -m755 $(3)
$(Q)$(RSYNC) --recursive \
             --links \
             --times \
             --perms \
             --delete \
             $(1) \
             $(abspath $(2))/ \
             $(abspath $(3))/
endef

define has_cmd
$(shell type '$(strip $(1))' 2>&1 >/dev/null && echo y)
endef

# Run install-info to register an info page into info directory
# $(1): pathname to info page to install
# $(2): pathname to info page directory
# $(3): optional directory entry name
# $(4): optional directory entry description
define install_info_recipe
$(call install_recipe,-m644,$(1),$(2)/$(notdir $(1)))
$(Q)$(INSTALL_INFO) $(if $(strip $(3)),--name="$(strip $(3))") \
                    $(if $(strip $(4)),--description="$(strip $(4))") \
                    $(2)/$(notdir $(1)) \
                    $(2)/dir
endef

# Run install-info to unregister an info page from info directory
# $(1): basename of info page to uninstall
# $(2): pathname to info page directory
define uninstall_info_recipe
$(Q)if [ -f $(2)/$(1) ]; then \
	$(INSTALL_INFO) --delete $(2)/$(1) $(2)/dir; \
fi
$(call rm_recipe,$(2)/$(1))
endef

# Extract man page section from file path given in argument
# $(1): pathname to man page
define man_section
$(shell echo $(notdir $(1)) | sed --silent 's/.*\.\([^.]\+\)/\1/pg')
endef

# Install a man page
# $(1): pathname to man page to install
# $(2): pathname to base man pages directory
define install_man_recipe
$(call install_recipe,-m644, \
                      $(1), \
                      $(2)/man$(call man_section,$(1))/$(notdir $(1)))
$(Q)$(MANDB) $(if $(Q),--quiet) $(2)
endef

# Remove installed man page
# $(1): basename of man page to uninstall
# $(2): pathname to base man pages directory
define uninstall_man_recipe
$(call rm_recipe,$(2)/man$(call man_section,$(1))/$(notdir $(1)))
$(Q)$(MANDB) $(if $(Q),--quiet) $(2)
endef

# List project files that are under revision control
define list_versioned_recipe
$(shell env GIT="$(GIT)" SVN="$(SVN)" \
        $(EBUILDDIR)/scripts/list_version_files.sh "$(TOPDIR)")
endef

.DEFAULT_GOAL := build

.SUFFIXES:
