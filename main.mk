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
export DATADIR       := $(abspath $(PREFIX)/share)
export DOCDIR        := $(abspath $(DATADIR)/doc)
export INFODIR       := $(abspath $(DATADIR)/info)
export MANDIR        := $(abspath $(DATADIR)/man)

export CC            := $(CROSS_COMPILE)gcc
export AR            := $(CROSS_COMPILE)gcc-ar
export LD            := $(CROSS_COMPILE)gcc
export STRIP         := $(CROSS_COMPILE)strip
export ECHOE         := /bin/echo -e
export RM            := rm -f
export LN            := ln -f
export PKG_CONFIG    := pkg-config
export INSTALL       := install
export RSYNC         := rsync
export KCONF         := kconfig-conf
export KMCONF        := kconfig-mconf
export KXCONF        := kconfig-qconf
export KGCONF        := kconfig-gconf
export KNCONF        := kconfig-nconf
export DOXY          := doxygen
export PYTHON        := python3
export SPHINXBUILD   := sphinx-build
export LATEXMK       := latexmk
export MAKEINFO      := makeinfo
export INSTALL_INFO  := install-info

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

.PHONY: doc
doc:

clean: clean-doc

.PHONY: clean-doc
clean-doc:

.PHONY: install-doc
install-doc:

uninstall: uninstall-doc

.PHONY: uninstall-doc
uninstall-doc:

# Handle doxygen targets only when $(doxyconf) is defined.
ifneq ($(strip $(doxyconf)),)
include $(EBUILDDIR)/doxy.mk
endif # ($(strip $(doxyconf)),)

# Handle sphinx targets only when $(sphinxsrc) is defined.
ifneq ($(strip $(sphinxsrc)),)
include $(EBUILDDIR)/sphinx.mk
endif # ($(strip $(sphinxsrc)),)

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

################################################################################
# Help handling
################################################################################

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
  xconfig       -- configure build using a QT menu-driven interface
  gconfig       -- configure build using a GTK menu-driven interface
  defconfig     -- configure build using default settings
  saveconfig    -- save current build configuration as default settings

::Documentation::
  doc           -- build documentation
  clean-doc     -- remove built documentation
  install-doc   -- install built documentation
  uninstall-doc -- remove installed documentation

::Construction::
  build         -- compile and link objects
  clean         -- remove built objects and documentation
  install       -- install built objects and documentation
  install-strip -- run `install' target and strip installed objects
  uninstall     -- remove installed objects and documentation
  distclean     -- run `clean' target then remove build configuration

::Help::
  help          -- this help message
  help-full     -- a full reference help message
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
PREFIX          -- prefix prepended to install location variables default value
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
    INCLUDEDIR PKGCONFIGDIR DATADIR DOCDIR INFODIR MANDIR
  * CROSS_COMPILE AR CC LD PKG_CONFIG EXTRA_CFLAGS EXTRA_LDFLAGS

::Install::
  * EBUILDDIR DEFCONFIG KCONF
  * BUILDDIR
  * PREFIX SYSCONFDIR BINDIR SBINDIR LIBDIR LIBEXECDIR LOCALSTATEDIR RUNSTATEDIR
    INCLUDEDIR  PKGCONFIGDIR DATADIR DOCDIR INFODIR MANDIR
  * CROSS_COMPILE STRIP
  * DESTDIR

::Tools::
  INSTALL LN RM ECHOE

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
                   [$(CROSS_COMPILE)]
  DEFCONFIG     -- default build configuration file
                   [$(DEFCONFIG)]
  DATADIR       -- read-only architecture-independent data install directory
                   [$(DATADIR)]
  DESTDIR       -- top-level staged / root install directory
                   [$(DESTDIR)]
  DOCDIR        -- documentation install directory
                   [$(DOCDIR)]
  EBUILDDIR     -- ebuild directory
                   [$(EBUILDDIR)]
  ECHOE         -- shell escaped string `echo' tool
                   [$(ECHOE)]
  EXTRA_CFLAGS  -- additional flags passed to $$(CC) at compile time
                   [$(EXTRA_CFLAGS)]
  EXTRA_LDFLAGS -- additional flags passed to $$(LD) at link time
                   [$(EXTRA_LDFLAGS)]
  INFODIR       -- Info files install directory
                   [$(INFODIR)]
  INCLUDEDIR    -- Header files install directory
                   [$(INCLUDEDIR)]
  INSTALL       -- `install' tool
                   [$(INSTALL)]
  KCONF         -- KConfig `conf' line-oriented tool
                   [$(KCONF)]
  KGCONF        -- KConfig `gconf' GTK menu based tool
                   [$(KGCONF)]
  KMCONF        -- Kconfig `mconf' NCurses menu based tool
                   [$(KMCONF)]
  KXCONF        -- Kconfig `qconf' QT menu based tool
                   [$(KXCONF)]
  LD            -- linker `ld' tool
                   [$(LD)]
  LIBDIR        -- libraries install directory
                   [$(LIBDIR)]
  LIBEXECDIR    -- executable programs install directory
                   [$(LIBEXECDIR)]
  LN            -- link maker `ln' tool
                   [$(LN)]
  LOCALSTATEDIR -- machine specific persistent data files install directory
                   [$(LOCALSTATEDIR)]
  MANDIR        -- man pages install directory
                   [$(MANDIR)]
  PREFIX        --  prefix prepended to install variable default values.
                   [$(PREFIX)]
  PKG_CONFIG    -- `pkg-config' compile and link helper tool
                   [$(PKG_CONFIG)]
  PKGCONFIGDIR  -- $$(PKG_CONFIG) metadata files install directory
                   [$(PKGCONFIGDIR)]
  RM            -- `rm' filesystem entry removal tool
                   [$(RM)]
  RUNSTATEDIR   -- machine specific temporary data files install directory
                   [$(RUNSTATEDIR)]
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
