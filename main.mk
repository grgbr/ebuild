################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

ifeq ($(realpath $(EBUILDDIR)),)
$(error Missing EBUILDDIR definition !)
endif
export EBUILDDIR

include $(EBUILDDIR)/vars.mk

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

ifeq ($(strip $(config-h)),)
$(error Missing '$(config-h)' configuration header path !)
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

ifneq ($(strip $(config-obj)),)

override config-obj := $(BUILDDIR)/$(config-obj)
override config-src := $(patsubst %.o,%.c,$(config-obj))

$(config-obj): $(config-src)
	@echo "  CC      $(@)"
	$(Q)$(CC) -MD -Wall -Wextra $(EXTRA_CFLAGS) -o $(@) -c $(<)

$(config-src): $(kconf_config) $(EBUILDDIR)/scripts/gen_conf_obj_src.sh
	@echo "  CONFSRC $(strip $(@))"
	$(EBUILDDIR)/scripts/gen_conf_obj_src.sh $(<) > $(@) || \
		{ $(RM) $(@); exit 1; }

.PHONY: _clean-config
_clean-config:
	$(if $(strip $(config-obj)),$(call rm_recipe,$(config-obj)))
	$(if $(strip $(config-src)),$(call rm_recipe,$(config-src)))

else  # !(ifneq ($(strip $(config-obj)),))

_clean-config:

endif # ifneq ($(strip $(config-obj)),)

else  # ifndef config-in

all_deps := $(ebuild_deps)

.PHONY: config
config menuconfig xconfig gconfig nconfig defconfig saveconfig:
	$(error Missing configuration template definition !)

endif # config-in

include $(EBUILDDIR)/rules.mk

clean: _clean-config

# Handle doxygen targets only when $(doxyconf) is defined.
include $(EBUILDDIR)/doxy.mk

# Handle sphinx targets only when $(sphinxsrc) is defined.
include $(EBUILDDIR)/sphinx.mk

# Handle source code tags targets only when $(tag-files) is defined.
include $(EBUILDDIR)/tags.mk

# Handle source distribution targets
include $(EBUILDDIR)/dist.mk

################################################################################
# Help handling
################################################################################

define help_section_msg :=


::Help::
  help          -- this help message
  help-full     -- a full reference help message
endef

# Help message common block
# $(1): project name
define help_common_msg
## $(strip $(1)) build usage ##

==Synopsis==

make <TARGET> [<VARIABLE>[=<VALUE>]]...

::Where::
  <TARGET>      -- one of the targets described in `Targets' section below
  <VARIABLE>    -- one of the variables described in the `Variables' section
                   below
  <VALUE>       -- a value to assign to the given <VARIABLE>

==Targets==

::Configuration::
  menuconfig    -- configure build using a NCurses menu-driven interface
  xconfig       -- configure build using a QT menu-driven interface
  gconfig       -- configure build using a GTK menu-driven interface
  defconfig     -- configure build using default settings
  saveconfig    -- save current build configuration as default settings

::Build::
  build         -- compile and link objects
  clean         -- remove built objects and documentation

::Install::
  install       -- install built objects and documentation
  install-strip -- run `install' target and strip installed objects
  uninstall     -- remove installed objects\
$(help_tags_targets)\
$(help_doc_targets)\
$(help_dist_targets)\
$(help_section_msg)
endef

# Short help message
# $(1): project name
define help_short_msg
$(call help_common_msg,$(1))

==Variables==

EBUILDDIR       -- directory where ebuild logic is located
                   [$(EBUILDDIR)]
DEFCONFIG       -- optional file containing default build configuration settings
                   [$(DEFCONFIG)]
PREFIX          -- prefix prepended to install location variables default value
                   [$(PREFIX)]
DESTDIR         -- root install hierarchy top-level directory
                   [$(DESTDIR)]
BUILDDIR        -- directory where intermediate built objects are generated
                   [$(BUILDDIR)]
CROSS_COMPILE   -- prefix prepended to executables used at compile / link time
                   [$(CROSS_COMPILE)]
EXTRA_CFLAGS    -- additional flags passed to $$(CC) at compile time
                   [$(EXTRA_CFLAGS)]
EXTRA_LDFLAGS   -- additional flags passed to $$(LD) at link time
                   [$(EXTRA_LDFLAGS)]

Use `help-full' target for further details.
endef

# Detailed help message
# $(1): project name
define help_full_msg
$(call help_common_msg,$(1))

==Variables==

::Configuration::
  * EBUILDDIR
  * DEFCONFIG
  * BUILDDIR
  * KCONF KGCONF KMCONF KNCONF KXCONF

::Build::
  * EBUILDDIR DEFCONFIG KCONF
  * BUILDDIR
  * PREFIX SYSCONFDIR BINDIR SBINDIR LIBDIR LIBEXECDIR LOCALSTATEDIR RUNSTATEDIR
    INCLUDEDIR PKGCONFIGDIR DATADIR
  * CROSS_COMPILE AR CC LD PKG_CONFIG EXTRA_CFLAGS EXTRA_LDFLAGS

::Install::
  * EBUILDDIR DEFCONFIG KCONF
  * BUILDDIR
  * PREFIX SYSCONFDIR BINDIR SBINDIR LIBDIR LIBEXECDIR LOCALSTATEDIR RUNSTATEDIR
    INCLUDEDIR  PKGCONFIGDIR DATADIR
  * CROSS_COMPILE STRIP
  * DESTDIR\
$(help_tags_vars)\
$(help_doc_vars)

::Tools::
  ECHOE INSTALL LN RM RSYNC PYTHON

::Reference::
  AR            -- objects archiver `ar'
                   [$(AR)]
  BINDIR        -- executable programs install directory
                   [$(BINDIR)]
  BUILDDIR      -- build directory
                   [$(BUILDDIR)]
  CC            -- C compiler `cc'
                   [$(CC)]
  CROSS_COMPILE -- cross compile tool prefix
                   [$(CROSS_COMPILE)]\
$(help_cscope_var)\
$(help_ctags_var)
  DEFCONFIG     -- default build configuration file
                   [$(DEFCONFIG)]
  DATADIR       -- read-only architecture-independent data install directory
                   [$(DATADIR)]\
$(help_doxy_var)
  DESTDIR       -- top-level staged / root install directory
                   [$(DESTDIR)]\
$(help_docdir_var)
  EBUILDDIR     -- ebuild directory
                   [$(EBUILDDIR)]
  ECHOE         -- shell escaped string `echo' tool
                   [$(ECHOE)]
  EXTRA_CFLAGS  -- additional flags passed to $$(CC) at compile time
                   [$(EXTRA_CFLAGS)]
  EXTRA_LDFLAGS -- additional flags passed to $$(LD) at link time
                   [$(EXTRA_LDFLAGS)]\
$(help_infodir_var)
  INCLUDEDIR    -- Header files install directory
                   [$(INCLUDEDIR)]
  INSTALL       -- `install' tool
                   [$(INSTALL)]\
$(help_install_info_var)
  KCONF         -- KConfig `conf' line-oriented tool
                   [$(KCONF)]
  KGCONF        -- KConfig `gconf' GTK menu based tool
                   [$(KGCONF)]
  KMCONF        -- Kconfig `mconf' NCurses menu based tool
                   [$(KMCONF)]
  KXCONF        -- Kconfig `qconf' QT menu based tool
                   [$(KXCONF)]\
$(help_latexmk_var)
  LD            -- linker `ld' tool
                   [$(LD)]
  LIBDIR        -- libraries install directory
                   [$(LIBDIR)]
  LIBEXECDIR    -- executable programs install directory
                   [$(LIBEXECDIR)]
  LN            -- link maker `ln' tool
                   [$(LN)]
  LOCALSTATEDIR -- machine specific persistent data files install directory
                   [$(LOCALSTATEDIR)]\
$(help_makeinfo_var)\
$(help_mandir_var)\
$(help_mandb_var)
  PREFIX        -- prefix prepended to install variable default values.
                   [$(PREFIX)]
  PKG_CONFIG    -- `pkg-config' compile and link helper tool
                   [$(PKG_CONFIG)]
  PKGCONFIGDIR  -- $$(PKG_CONFIG) metadata files install directory
                   [$(PKGCONFIGDIR)]
  PYTHON        -- `python3' interpreter
                   [$(PYTHON)]
  RM            -- `rm' filesystem entry removal tool
                   [$(RM)]
  RSYNC         -- `rsync' filesystem synchronization tool
                   [$(RSYNC)]
  RUNSTATEDIR   -- machine specific temporary data files install directory
                   [$(RUNSTATEDIR)]\
$(help_sphinxbuild_var)
  SBINDIR       -- system administration executable programs install directory
                   [$(SBINDIR)]
  STRIP         -- `strip' object symbols discarding tool.
                   [$(STRIP)]
  SYSCONFDIR    -- machine specific read-only configuration install directory
                   [$(SYSCONFDIR)]
endef

.PHONY: help
help: SHELL := bash
help:
	@$(call echo_multi_line,$(call help_short_msg,$(PACKAGE)))

.PHONY: help
help-full: SHELL := bash
help-full:
	@$(call echo_multi_line,$(call help_full_msg,$(PACKAGE)))
