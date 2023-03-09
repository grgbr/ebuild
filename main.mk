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

################################################################################
# Doxygen handling
#
# For doxygen generation to properly work, the doxygen must be given the
# location where to generate output files. This is performed by passing the
# OUTDIR variable into doxygen tool environment (see doxy_recipe() macro
# definition).
# This requires the Doxyfile configuration file to contain the following output
# directory definition:
#     OUTPUT_DIRECTORY = $(OUTDIR)
#
# In addition, if combined with Sphinx / breathe documentation system, the
# doxygen tool must be setup to generate XML output to a "xml" directory located
# right under the directory pointed to by the OUTDIR variable mentioned above.
# This requires the Doxyfile configuration file to contain the following XML
# output directory definition:
#
#     XML_OUTPUT = xml
#
# See below for more about sphinx / breathe setup.
###############################################################################

# Handle doxygen targets only when $(doxyconf) is defined.
ifneq ($(strip $(doxyconf)),)

# Doxygen build directories, i.e. where doxygen generates its output files.
doxydir    := $(BUILDDIR)/doc/doxy
doxyxmldir := $(doxydir)/xml

doc: doxy

clean-doc: clean-doxy

.PHONY: clean-doxy
clean-doxy:
	$(call rmr_recipe,$(doxydir))

$(doxydir):
	@mkdir -p $(@)

ifneq ($(call has_cmd,$(DOXY)),y)

# Make doxy target depend on every other build targets so that doxygen may
# build documentation for generated sources if needed.
.PHONY: doxy
doxy: $(build_prereqs) | $(doxydir)
	$(call doxy_recipe,$(doxyconf),$(|),$(doxyenv))

else  # !($(call has_cmd,$(DOXY)),y)

.PHONY: doxy
doxy:
	$(error doxygen tool not found ! \
	        Setup $$(DOXY) to generate documentation)

endif # ($(call has_cmd,$(DOXY)),y)

endif # ($(strip $(doxyconf)),)

################################################################################
# Sphinx handling
#
# When using breathe / doxygen combination for source code documentation
# generation, breathe must be given the location where to retrieve doxygen XML
# generated output.
# This is performed by passing the DOXYXMLDIR variable into sphinx environment
# (see the html target recipe for example).
# This requires the sphinx configuration file (conf.py) to instruct breathe
# the pathname to doxygen XML generated output:
#
#     # Get doxygen XML generated output directory
#     doxyxmldir = os.getenv('DOXYXMLDIR')
#     if not os.path.isdir(doxyxmldir):
#         print('{}: Invalid Doxygen XML directory'.format(os.path.basename(sys.argv[0])),
#               file=sys.stderr)
#         sys.exit(1)
#
#     # Setup breathe default project name
#     breathe_default_project        = 'myproject'
#     # For default project, tell breathe to search for XML input into doxygen
#     # XML generated output # directory.
#     breathe_projects               = { 'myproject': doxyxmldir }
#
# See above for informations about how to enable doxygen output.
################################################################################

# Handle Sphinx targets only when $(sphinxsrc) is defined.
ifneq ($(strip $(sphinxsrc)),)

override docdir  := $(DESTDIR)$(DOCDIR)/$(PACKAGE)
override infodir := $(DESTDIR)$(INFODIR)

define sphinx_list_docs_cmd
import os
import doc.conf as cfg

print(*[os.path.splitext(doc[1])[0] for doc in cfg.$(1)])
endef

define sphinx_list_docs
$(shell $(PYTHON) -c '$(call sphinx_list_docs_cmd,$(1))')
endef

define sphinx_list_pdf
$(notdir $(addsuffix .pdf,$(call sphinx_list_docs,latex_documents)))
endef

define sphinx_list_info
$(notdir $(addsuffix .info,$(call sphinx_list_docs,texinfo_documents)))
endef

# Sphinx generated HTML documentation output directory
sphinxdir      := $(BUILDDIR)/doc/sphinx
sphinxcachedir := $(BUILDDIR)/doc/doctrees
sphinxhtmldir  := $(BUILDDIR)/doc/html
sphinxpdfdir   := $(BUILDDIR)/doc/pdf
sphinxinfodir  := $(BUILDDIR)/doc/info

doc: html pdf info

clean-doc: clean-sphinx

.PHONY: clean-sphinx
clean-sphinx: clean-html clean-pdf
	$(call rm_recipe,$(sphinxdir))
	$(call rmr_recipe,$(sphinxcachedir))

.PHONY: clean-html
clean-html:
	$(call rmr_recipe,$(sphinxhtmldir))

.PHONY: clean-pdf
clean-pdf:
	$(call rmr_recipe,$(sphinxpdfdir))

.PHONY: clean-info
clean-info:
	$(call rmr_recipe,$(sphinxinfodir))

install-doc: install-html install-pdf install-info

uninstall-doc: uninstall-html uninstall-pdf uninstall-info

.PHONY: uninstall-html
uninstall-html:
	$(call rmr_recipe,$(docdir)/html)

.PHONY: uninstall-pdf
uninstall-pdf:
	$(call uninstall_recipe,$(docdir),$(sphinx_list_pdf))

.PHONY: uninstall-info
uninstall-info:
	$(foreach page, \
	          $(sphinx_list_info), \
	          $(call uninstall_info_recipe,$(page),$(infodir))$(newline))

ifneq ($(call has_cmd,$(SPHINXBUILD)),y)

# Make html target depend onto doxy target if doxygen support is enabled.
.PHONY: html
html: $(build_prereqs) $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_html_recipe,$(sphinxdir), \
	                          $(sphinxhtmldir), \
	                          $(sphinxcachedir), \
	                          $(sphinxenv) DOXYXMLDIR="$(doxyxmldir)")

.PHONY: install-html
install-html: html
	$(call installdir_recipe,--chmod=D755 --chmod=F644, \
	                         $(sphinxhtmldir), \
	                         $(docdir)/html)

# Make pdf target depend onto doxy target if doxygen support is enabled.
.PHONY: pdf
pdf: $(build_prereqs) $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_pdf_recipe,$(sphinxdir), \
	                         $(sphinxpdfdir), \
	                         $(sphinxcachedir), \
	                         $(sphinxenv) DOXYXMLDIR="$(doxyxmldir)")

.PHONY: install-pdf
install-pdf: pdf
	$(foreach pdf, \
	          $(sphinx_list_pdf), \
	          $(call install_recipe, \
	                 -m644, \
	                 $(sphinxpdfdir)/$(pdf), \
	                 $(docdir)/$(pdf))$(newline))

# Make info target depend onto doxy target if doxygen support is enabled.
.PHONY: info
info: $(build_prereqs) $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_info_recipe,$(sphinxdir), \
	                          $(sphinxinfodir), \
	                          $(sphinxcachedir), \
	                          $(sphinxenv) DOXYXMLDIR="$(doxyxmldir)")

.PHONY: install-info
install-info: info
	$(foreach page, \
	          $(sphinx_list_info), \
	          $(call install_info_recipe,\
	                 $(sphinxinfodir)/$(page),\
	                 $(infodir))$(newline))

$(sphinxdir): | $(sphinxsrc)
	@ln -sf $(|) $(@)

else  # !($(call has_cmd,$(SPHINXBUILD)),y)

.PHONY: html install-html pdf install-pdf info install-info
html install-html pdf install-pdf info install-info:
	$(error sphinx-build tool not found ! \
	        Setup $$(SPHINXBUILD) to generate documentation)

endif # ($(call has_cmd,$(SPHINXBUILD)),y)

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
