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

ifneq ($(call has_cmd,$(DOXY)),y)
$(error Doxygen tool not found ! Setup $$(DOXY) to generate documentation)
endif # ($(call has_cmd,$(DOXY)),y)

# Doxygen build base directory, i.e. where doxygen generates its output files.
override doxydir    := $(BUILDDIR)/doc/doxy
# Doxygen XML build directory, i.e. where doxygen generates its output XML
# files.
override doxyxmldir := $(doxydir)/xml

# Run doxygen
# $(1): pathname to Doxyfile
# $(2): pathname to generated documentation base output directory
# $(3): additional environment variables given to doxygen
define doxy_recipe
@echo "  DOXY    $(strip $(2))"
$(Q)env OUTDIR="$(strip $(2))" $(3) $(if $(Q),QUIET="YES",QUIET="NO") \
        $(DOXY) \
        $(1)
endef

doc: doxy

# Make doxy target depend on every other build targets so that doxygen may
# build documentation for generated sources if needed.
.PHONY: doxy
doxy: $(build_prereqs) | $(doxydir)
	$(call doxy_recipe,$(doxyconf),$(|),$(doxyenv))


clean-doc: clean-doxy

.PHONY: clean-doxy
clean-doxy:
	$(call rmr_recipe,$(doxydir))

$(doxydir):
	@mkdir -p $(@)
