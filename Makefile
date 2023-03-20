override PACKAGE := ebuild
override VERSION := 1.0

include vars.mk
include helpers.mk

sphinxsrc := $(TOPDIR)/sphinx
include sphinx.mk

destdatadir   := $(DESTDIR)$(DATADIR)/ebuild
install_files := $(notdir $(wildcard $(TOPDIR)/*.mk))

.PHONY: build
build: doc

.PHONY: clean
clean:
	$(call rmr_recipe,$(BUILDDIR))

.PHONY: install
install: install-doc
	$(foreach f, \
	          $(install_files), \
	          $(call install_recipe,-m644, \
	                                $(f), \
	                                $(destdatadir)/$(f))$(newline))

.PHONY: uninstall
uninstall: uninstall-doc
	$(call uninstall_recipe,$(destdatadir),$(install_files))

.PHONY: distclean
distclean: clean
