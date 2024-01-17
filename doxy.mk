################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

################################################################################
# Doxygen handling
#
# For doxygen generation to properly work, the doxygen tool must be given the
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

ifneq ($(strip $(doxyconf)),)

ifeq ($(strip $(PACKAGE)),)
$(error Missing package name definition ! \
        Setup $$(PACKAGE) to generate documentation)
endif # ($(strip $(PACKAGE)),)

ifeq ($(strip $(VERSION)),)
$(error Missing version definition ! \
        Setup $$(VERSION) to generate documentation)
endif # ($(strip $(VERSION)),)

# Doxygen build base directory, i.e. where doxygen generates its output files.
override doxydir      := $(BUILDDIR)/doc/doxy
# Doxygen XML build directory, i.e. where doxygen generates its output XML
# files.
override doxyxmldir   := $(doxydir)/xml

# Run doxygen
# $(1): pathname to Doxyfile
# $(2): pathname to generated documentation base output directory
# $(3): additional environment variables given to doxygen
define doxy_recipe
@echo "  DOXY    $(strip $(2))"
$(Q)env OUTDIR="$(strip $(2))" \
        $(3) \
        PACKAGE="$(PACKAGE)" \
        VERSION="$(VERSION)" \
        CONFDEFS="$(doxy_conf_defs)" \
        CONFDOC="$(doxyconfdoc)" \
        $(if $(Q),QUIET="YES",QUIET="NO") \
        $(DOXY) \
        $(1)
endef

doc: doxy

# Make doxy target depend on every other build targets so that doxygen may
# build documentation for generated sources if needed.
.PHONY: doxy
doxy: | $(doxydir)
	$(call has_cmd_or_die,DOXY)
	$(call doxy_recipe,$(doxyconf),$(|),$(doxyenv))

ifneq ($(strip $(config-in)),)

# Build configuration Doxygen documentation file.
override doxyconfdoc := $(doxydir)/config.dox

define doxy_conf_defs
$(shell cat $(doxyconfdoc) | \
        $(CC) -P -dM -fpreprocessed -E - | \
        awk '/^#define[[:blank:]]+CONFIG_/ { print $$2 "=" $$3 }')
endef

doxy: $(doxyconfdoc)

$(doxyconfdoc): $(config-in) $(EBUILDDIR)/scripts/gen_conf_doc.py | $(doxydir)
	$(call has_cmd_or_die,DOXY)
	@echo "  CONFDOC $(strip $(@))"
	$(EBUILDDIR)/scripts/gen_conf_doc.py --output $(@) $(<) $(PACKAGE)

endif # ($(strip $(config-in)),)

clean: clean-doc

.PHONY: clean-doc
clean-doc: clean-doxy

.PHONY: clean-doxy
clean-doxy:
	$(call rmr_recipe,$(doxydir))

$(doxydir):
	@mkdir -p $(@)

define help_doxy_var :=

  DOXY          -- `doxygen' documentation generation tool
                   [$(DOXY)]
endef

endif # ifneq ($(strip $(doxyconf)),)
