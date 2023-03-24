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

print(*[os.path.splitext(doc[1])[0] for doc in cfg.$(1)]);
endef

define sphinx_list_docs
$(shell cd $(sphinxsrc); \
        $(PYTHON) -X pycache_prefix="$(abspath $(BUILDDIR))/__pycache__" \
                  -c '$(call sphinx_list_docs_cmd,$(1))')
endef

define sphinx_list_pdf
$(notdir $(addsuffix .pdf,$(call sphinx_list_docs,latex_documents)))
endef

define sphinx_list_info
$(notdir $(addsuffix .info,$(call sphinx_list_docs,texinfo_documents)))
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
             all-pdf \
             PDFLATEX='$(LATEXMK) -pdf -dvi- -ps-' \
             LATEXMKOPTS='-interaction=nonstopmode -halt-on-error' \
             $(if $(Q),>/dev/null 2>&1)
endef

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
             info \
             MAKEINFO='$(MAKEINFO) --no-split' \
             $(if $(Q),>/dev/null 2>&1)
endef

# Final destination documentation install directory
override docdir         := $(DESTDIR)$(DOCDIR)/$(PACKAGE)
# Final destination (tex)info page install directory
override infodir        := $(DESTDIR)$(INFODIR)
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

$(sphinxdir): | $(sphinxsrc)
	@mkdir -p $(dir $(@))
	@$(LN) -s $(|) $(@)

clean-doc: clean-sphinx

.PHONY: clean-sphinx
clean-sphinx:
	$(call rm_recipe,$(sphinxdir))
	$(call rmr_recipe,$(sphinxcachedir))

################################################################################
# HTML handling
################################################################################

doc: html

# Make html target depend onto doxy target if doxygen support is enabled.
.PHONY: html
html: $(build_prereqs) $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_html_recipe,$(sphinxdir), \
	                          $(sphinxhtmldir), \
	                          $(sphinxcachedir), \
	                          $(sphinxenv) DOXYXMLDIR="$(doxyxmldir)")

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
pdf: $(build_prereqs) $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_pdf_recipe,$(sphinxdir), \
	                         $(sphinxpdfdir), \
	                         $(sphinxcachedir), \
	                         $(sphinxenv) DOXYXMLDIR="$(doxyxmldir)")

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
info: $(build_prereqs) $(if $(doxyconf),doxy) | $(sphinxdir)
	$(call sphinx_info_recipe,$(sphinxdir), \
	                          $(sphinxinfodir), \
	                          $(sphinxcachedir), \
	                          $(sphinxenv) DOXYXMLDIR="$(doxyxmldir)")

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