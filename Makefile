################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

override PACKAGE := ebuild
override VERSION := 1.0

export PACKAGE VERSION

include vars.mk
include helpers.mk

sphinxsrc := $(TOPDIR)/sphinx
include sphinx.mk

.DEFAULT_GOAL := help

destdatadir   := $(DESTDIR)$(DATADIR)/ebuild
install_files := $(patsubst $(TOPDIR)/%,%,$(wildcard $(TOPDIR)/*.mk) \
                                          $(wildcard $(TOPDIR)/scripts/*))

.PHONY: build
build:

.PHONY: clean
clean:
	$(call rmr_recipe,$(BUILDDIR))

.NOTPARALLEL: doc
.PHONY: doc
doc:

.PHONY: install
install:
	$(foreach f, \
	          $(install_files), \
	          $(call install_recipe,-m644, \
	                                $(f), \
	                                $(destdatadir)/$(f))$(newline))

.PHONY: uninstall
uninstall: uninstall-doc
	$(call uninstall_recipe,$(destdatadir),$(install_files))

override distfiles = $(list_versioned_recipe)
include dist.mk

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

::Build::
  build         -- compile and link objects
  clean         -- remove built objects and documentation

::Install::
  install       -- install built objects and documentation
  uninstall     -- remove installed objects and documentation

::Documentation::
  doc           -- build documentation
  clean-doc     -- remove built documentation
  install-doc   -- install built documentation
  uninstall-doc -- remove installed documentation

::Distribution::
  dist          -- build source distribution tarball
  distclean     -- run `clean' target, remove build configuration and
                   distribution tarball

 ::Help::
  help          -- this help message
  help-full     -- a full reference help message
endef

# Short help message
# $(1): project name
define help_short_msg
$(call help_common_msg,$(1))

==Variables==

PREFIX          -- prefix prepended to install location variables default value
                   [$(PREFIX)]
DESTDIR         -- root install hierarchy top-level directory
                   [$(DESTDIR)]
BUILDDIR        -- directory where intermediate built objects are generated
                   [$(BUILDDIR)]

Use `help-full' target for further details.
endef

# Detailed help message
# $(1): project name
define help_full_msg
$(call help_common_msg,$(1))

==Variables==

::Build::
  * BUILDDIR
  * PREFIX DATADIR

::Install::
  * EBUILDDIR DEFCONFIG KCONF
  * BUILDDIR
  * PREFIX DATADIR
  * DESTDIR

::Documentation::
  * DOCDIR INFODIR
  * INSTALL_INFO LATEXMK MAKEINFO PYTHON SPHINXBUILD

::Tools::
  ECHOE INSTALL LN RM RSYNC

::Reference::
  BUILDDIR     -- build directory
                  [$(BUILDDIR)]
  DATADIR      -- read-only architecture-independent data install directory
                  [$(DATADIR)]
  DESTDIR      -- top-level staged / root install directory
                  [$(DESTDIR)]
  DOCDIR       -- documentation install directory
                  [$(DOCDIR)]
  ECHOE        -- shell escaped string `echo' tool
                  [$(ECHOE)]
  INFODIR      -- Info files install directory
                  [$(INFODIR)]
  INSTALL      -- `install' tool
                  [$(INSTALL)]
  INSTALL_INFO -- `install-info' Texinfo info page installer tool
                  [$(INSTALL_INFO)]
  LATEXMK      -- `latexmk' LaTeX documentation builder tool
                  [$(LATEXMK)]
  LN           -- link maker `ln' tool
                  [$(LN)]
  MAKEINFO     -- `makeinfo' Texinfo documentation conversion tool
                  [$(MAKEINFO)]
  PREFIX       --  prefix prepended to install variable default values.
                  [$(PREFIX)]
  PYTHON       -- `python3' interpreter
                  [$(PYTHON)]
  RM           -- `rm' filesystem entry removal tool
                  [$(RM)]
  RSYNC        -- `rsync' filesystem synchronization tool
                  [$(RSYNC)]
  SPHINXBUILD  -- `sphinx-build' documentation generation tool
                  [$(SPHINXBUILD)]
endef

.PHONY: help
help: SHELL := bash
help:
	@$(call echo_multi_line,$(call help_short_msg,$(PACKAGE)))

.PHONY: help
help-full: SHELL := bash
help-full:
	@$(call echo_multi_line,$(call help_full_msg,$(PACKAGE)))
