################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

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

ifneq ($(strip $(sphinxsrc)),)

ifneq ($(call has_cmd,$(SPHINXBUILD)),y)
$(error sphinx-build tool not found ! \
        Setup $$(SPHINXBUILD) to generate documentation)
endif # ($(call has_cmd,$(SPHINXBUILD)),y)

# Source / import conf.py configuration file from sphinx documentation directory
# and retrieve the list of generated output files according to the type of
# document given in argument.
define sphinx_list_docs_cmd
import os;
import conf as cfg;

hasattr(cfg, "$(1)") and print(*[os.path.splitext(doc[1])[0] for doc in cfg.$(1)]);
endef

define sphinx_list_docs
$(shell cd $(sphinxsrc); \
        env $(sphinxenv) \
        $(PYTHON) -X pycache_prefix="$(abspath $(BUILDDIR))/__pycache__" \
                  -c '$(call sphinx_list_docs_cmd,$(1))')
endef

define sphinx_list_pdf
$(notdir $(addsuffix .pdf,$(call sphinx_list_docs,latex_documents)))
endef

define sphinx_list_info
$(notdir $(addsuffix .info,$(call sphinx_list_docs,texinfo_documents)))
endef

# Source / import conf.py configuration file from sphinx documentation directory
# and retrieve the list of generated man pages
define sphinx_list_man_cmd
import conf as cfg;

hasattr(cfg, "man_pages") and print(*[doc[1] + "." + str(doc[4]) for doc in cfg.man_pages]);
endef

define sphinx_list_man
$(notdir \
  $(shell cd $(sphinxsrc); \
          env $(sphinxenv) \
          $(PYTHON) -X pycache_prefix="$(abspath $(BUILDDIR))/__pycache__" \
                    -c '$(sphinx_list_man_cmd)'))
endef

# Return top-level directory menu entry attribute of info page given in
# argument.
# $(1): info page file basename
# $(2): integer identifier of attribute to retrieve
#
# Parse the `texinfo_documents' list found into Sphinx configuration file,
# find the tuple specifying attributes related to the info page given as
# argument $(1), and return the value of attribute identified by argument $(2).
#
# texinfo_documents is a list of tuples structured according to the document
# found here:
#     https://www.sphinx-doc.org/en/master/usage/configuration.html#confval-texinfo_documents
# Argument $(2) is an integer identifying the tuple element to extract.
define sphinx_info_menu_cmd
import os;
import conf as cfg;

print([doc[$(2)] for doc in cfg.texinfo_documents if doc[1] == os.path.splitext("$(1)")[0]][0])
endef

# Return top-level directory menu entry attribute of info page given in
# argument.
# $(1): info page file basename
# $(2): integer identifier of attribute to retrieve
#
# See sphinx_info_menu_cmd macro for more informations.
define sphinx_info_menu
$(shell cd $(sphinxsrc); \
        $(PYTHON) -X pycache_prefix="$(abspath $(BUILDDIR))/__pycache__" \
                  -c '$(call sphinx_info_menu_cmd,$(1),$(2))')
endef

# Return top-level directory menu entry name of info page given in argument.
# $(1): info page file basename
#
# Probe the `texinfo_documents' list found into Sphinx configuration file and
# extract the menu entry name related to the info page given as argument $(1).
define sphinx_info_menu_name
$(call sphinx_info_menu,$(1),4)
endef

# Return top-level directory menu entry description of info page given in
# argument.
# $(1): info page file basename
#
# Probe the `texinfo_documents' list found into Sphinx configuration file and
# extract the menu entry description related to the info page given as argument
# $(1).
define sphinx_info_menu_desc
$(call sphinx_info_menu,$(1),5)
endef

# Run sphinx-build to generate HTML
# $(1): pathname to sphinx documentation source directory
# $(2): pathname to generated HTML documentation output directory
# $(3): pathname to sphinx cache directory
# $(4): additional environment variables given to sphinx-build
define sphinx_html_recipe
@echo "  HTML    $(strip $(2))"
$(Q)$(if $(4),env $(4)) \
    $(SPHINXBUILD) -b html \
                   "$(strip $(1))" \
                   "$(strip $(2))" \
                   $(if $(Q),-Q,-q) \
                   -d "$(strip $(3))" \
                   -a \
                   -E \
                   -j auto
endef

ifneq ($(strip $(sphinx_list_pdf)),)

# Run sphinx-build to generate PDF
# $(1): pathname to sphinx documentation source directory
# $(2): pathname to generated PDF documentation output directory
# $(3): pathname to sphinx cache directory
# $(4): additional environment variables given to sphinx-build
define sphinx_pdf_recipe
@echo "  LATEX   $(strip $(2))"
$(Q)$(if $(4),env $(4)) \
    $(SPHINXBUILD) -b latex \
                   "$(strip $(1))" \
                   "$(strip $(2))" \
                   $(if $(Q),-Q,-q) \
                   -d "$(strip $(3))" \
                   -a \
                   -E \
                   -j auto
@echo "  PDF     $(strip $(2))"
+$(Q)$(MAKE) --directory "$(strip $(2))" \
             $(if $(Q),--output-sync=none) \
             all-pdf \
             PDFLATEX='$(LATEXMK) -pdf -dvi- -ps-' \
             LATEXMKOPTS='-interaction=nonstopmode -halt-on-error' \
             $(if $(Q),>/dev/null 2>&1)
endef

endif # ifneq ($(strip $(sphinx_list_pdf)),)

ifneq ($(strip $(sphinx_list_info)),)

# Run sphinx-build to generate info pages
# $(1): pathname to sphinx documentation source directory
# $(2): pathname to generated info documentation output directory
# $(3): pathname to sphinx cache directory
# $(4): additional environment variables given to sphinx-build
define sphinx_info_recipe
@echo "  TEXINFO $(strip $(2))"
$(Q)$(if $(4),env $(4)) \
    $(SPHINXBUILD) -b texinfo \
                   "$(strip $(1))" \
                   "$(strip $(2))" \
                   $(if $(Q),-Q,-q) \
                   -d "$(strip $(3))" \
                   -a \
                   -E \
                   -j auto
@echo "  INFO    $(strip $(2))"
+$(Q)$(MAKE) --directory "$(strip $(2))" \
             $(if $(Q),--output-sync=none) \
             info \
             MAKEINFO='$(MAKEINFO) --no-split' \
             $(if $(Q),>/dev/null 2>&1)
endef

endif # ifneq ($(strip $(sphinx_list_info)),)

# Final destination documentation install directory
override docdir         := $(DESTDIR)$(DOCDIR)/$(PACKAGE)
# Final destination (tex)info page install directory
override infodir        := $(DESTDIR)$(INFODIR)
# Final destination man pages install directory
override mandir         := $(DESTDIR)$(MANDIR)
# Sphinx generated documentation base output directory
override sphinxdir      := $(BUILDDIR)/doc/sphinx
# Internal sphinx doctrees / caching directory
override sphinxcachedir := $(BUILDDIR)/doc/doctrees
# Sphinx generated HTML documentation output directory
override sphinxhtmldir  := $(BUILDDIR)/doc/html
# Sphinx generated PDF documentation output directory
override sphinxpdfdir   := $(BUILDDIR)/doc/pdf
# Sphinx generated (tex)info page output directory
override sphinxinfodir  := $(BUILDDIR)/doc/info
# Sphinx generated man pages output directory
override sphinxmandir   := $(BUILDDIR)/doc/man

# Used by dist target to generate documentation when enabled
doc_dist_targets := doc

# Used by dist target to install documentation when enabled
define doc_dist_cmds =
$(call installdir_recipe,--chmod=D755 --chmod=F644, \
                         $(sphinxhtmldir), \
                         $(distdir)/docs/html)
$(foreach f, \
          $(sphinx_list_pdf), \
          $(call install_recipe,--mode=644, \
                                $(sphinxpdfdir)/$(f), \
                                $(distdir)/docs/$(f))$(newline))
$(foreach f, \
          $(sphinx_list_info), \
          $(call install_recipe,--mode=644, \
                                $(sphinxinfodir)/$(f), \
                                $(distdir)/docs/info/$(f))$(newline))
$(foreach f, \
          $(sphinx_list_man), \
          $(call install_recipe,--mode=644, \
                                $(sphinxmandir)/$(f), \
                                $(distdir)/docs/man/$(f))$(newline))
endef

# Sphinx does not like running multiple generation processes in parallel.
.NOTPARALLEL: doc
.PHONY: doc

$(sphinxdir): | $(sphinxsrc)
	@mkdir -p $(dir $(@))
	@$(LN) -s $(|) $(@)

clean: clean-doc

.PHONY: clean-doc
clean-doc: clean-sphinx

.PHONY: clean-sphinx
clean-sphinx:
	$(call rm_recipe,$(sphinxdir))
	$(call rmr_recipe,$(sphinxcachedir))

.PHONY: install-doc

.PHONY: uninstall-doc
uninstall: uninstall-doc

################################################################################
# HTML handling
################################################################################

doc: html

# Make html target depend onto doxy target if doxygen support is enabled.
.PHONY: html
html: $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_html_recipe,$(sphinxdir), \
	                          $(sphinxhtmldir), \
	                          $(sphinxcachedir), \
	                          $(sphinxenv) \
	                          DOCDIR="$(docdir)" \
	                          DOXYXMLDIR="$(doxyxmldir)")

clean-sphinx: clean-html

.PHONY: clean-html
clean-html:
	$(call rmr_recipe,$(sphinxhtmldir))

install-doc: install-html

.PHONY: install-html
install-html: html
	$(call installdir_recipe,--chmod=D755 --chmod=F644, \
	                         $(sphinxhtmldir), \
	                         $(docdir)/html)

uninstall-doc: uninstall-html

.PHONY: uninstall-html
uninstall-html:
	$(call rmr_recipe,$(docdir)/html)

################################################################################
# PDF handling
################################################################################

doc: pdf

# Make pdf target depend onto doxy target if doxygen support is enabled.
.PHONY: pdf
pdf: $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_pdf_recipe,$(sphinxdir), \
	                         $(sphinxpdfdir), \
	                         $(sphinxcachedir), \
	                         $(sphinxenv) \
	                         DOCDIR="$(docdir)" \
	                         DOXYXMLDIR="$(doxyxmldir)")

clean-sphinx: clean-pdf

.PHONY: clean-pdf
clean-pdf:
	$(call rmr_recipe,$(sphinxpdfdir))

install-doc: install-pdf

.PHONY: install-pdf
install-pdf: pdf
	$(foreach pdf, \
	          $(sphinx_list_pdf), \
	          $(call install_recipe, \
	                 -m644, \
	                 $(sphinxpdfdir)/$(pdf), \
	                 $(docdir)/$(pdf))$(newline))

uninstall-doc: uninstall-pdf

.PHONY: uninstall-pdf
uninstall-pdf:
	$(call uninstall_recipe,$(docdir),$(sphinx_list_pdf))

################################################################################
# (Tex)info page handling
################################################################################

doc: info

# Make info target depend onto doxy target if doxygen support is enabled.
.PHONY: info
info: $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_info_recipe,$(sphinxdir), \
	                          $(sphinxinfodir), \
	                          $(sphinxcachedir), \
	                          $(sphinxenv) \
	                          DOCDIR="$(docdir)" \
	                          DOXYXMLDIR="$(doxyxmldir)")

clean-sphinx: clean-info

.PHONY: clean-info
clean-info:
	$(call rmr_recipe,$(sphinxinfodir))

install-doc: install-info

.PHONY: install-info
install-info: info
	$(foreach page, \
	          $(sphinx_list_info), \
	          $(call install_info_recipe,\
	                 $(sphinxinfodir)/$(page),\
	                 $(infodir),\
	                 $(call sphinx_info_menu_name,$(page)),\
	                 $(call sphinx_info_menu_desc,$(page)))$(newline))

uninstall-doc: uninstall-info

.PHONY: uninstall-info
uninstall-info:
	$(foreach page, \
	          $(sphinx_list_info), \
	          $(call uninstall_info_recipe,$(page),$(infodir))$(newline))

################################################################################
# Manual pages handling
################################################################################

ifneq ($(strip $(sphinx_list_man)),)

# Run sphinx-build to generate man pages
# $(1): pathname to sphinx documentation source directory
# $(2): pathname to generated man pages output directory
# $(3): pathname to sphinx cache directory
# $(4): additional environment variables given to sphinx-build
define sphinx_man_recipe
@echo "  MAN     $(strip $(2))"
$(Q)$(if $(4),env $(4)) \
    $(SPHINXBUILD) -b man \
                   "$(strip $(1))" \
                   "$(strip $(2))" \
                   $(if $(Q),-Q,-q) \
                   -d "$(strip $(3))" \
                   -a \
                   -E \
                   -j auto
endef

endif # ifneq ($(strip $(sphinx_list_man)),)

doc: man

# Make man target depend onto doxy target if doxygen support is enabled.
.PHONY: man
man: $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_man_recipe,$(sphinxdir), \
	                         $(sphinxmandir), \
	                         $(sphinxcachedir), \
	                         $(sphinxenv) \
	                         DOCDIR="$(docdir)" \
	                         MANDIR="$(mandir)" \
	                         DOXYXMLDIR="$(doxyxmldir)")

clean-sphinx: clean-man

.PHONY: clean-man
clean-man:
	$(call rmr_recipe,$(sphinxmandir))

install-doc: install-man

.PHONY: install-man
install-man: man
	$(foreach page, \
	          $(sphinx_list_man), \
	          $(call install_man_recipe, \
	                 $(sphinxmandir)/$(page), \
	                 $(mandir))$(newline))

uninstall-doc: uninstall-man

.PHONY: uninstall-man
uninstall-man:
	$(foreach page, \
	          $(sphinx_list_man), \
	          $(call uninstall_man_recipe,$(page),$(mandir))$(newline))


define help_doc_targets :=


::Documentation::
  doc           -- build documentation
  clean-doc     -- remove built documentation
  install-doc   -- install built documentation
  uninstall-doc -- remove installed documentation
endef

define help_doc_vars :=


::Documentation::
  * DOCDIR INFODIR MANDIR
  * $(strip $(if $(strip $(doxyconf)),DOXY) \
            INSTALL_INFO LATEXMK MAKEINFO MANDB SPHINXBUILD)
endef

define help_docdir_var :=

  DOCDIR        -- documentation install directory
                   [$(DOCDIR)]
endef

define help_infodir_var :=

  INFODIR       -- Info files install directory
                   [$(INFODIR)]
endef

define help_mandir_var :=

  MANDIR        -- man pages install directory
                   [$(MANDIR)]
endef

define help_mandb_var :=

  MANDB         -- man pages index maintainer tool
                   [$(MANDB)]
endef

define help_install_info_var :=

  INSTALL_INFO  -- `install-info' Texinfo info page installer tool
                   [$(INSTALL_INFO)]
endef

define help_latexmk_var :=

  LATEXMK       -- `latexmk' LaTeX documentation builder tool
                   [$(LATEXMK)]
endef

define help_makeinfo_var :=

  MAKEINFO      -- `makeinfo' Texinfo documentation conversion tool
                   [$(MAKEINFO)]
endef

define help_sphinxbuild_var :=

  SPHINXBUILD   -- `sphinx-build' documentation generation tool
                   [$(SPHINXBUILD)]
endef

endif # ifneq ($(strip $(sphinxsrc)),)
