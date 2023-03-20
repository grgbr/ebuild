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

define sync_src_recipe
@echo "  SYNC    $(strip $(1))"
$(Q)mkdir -p -m755 $(1)
$(Q)env GIT=$(GIT) SVN="$(SVN)" \
    $(CURDIR)/scripts/list_version_files.sh | \
    $(RSYNC) --recursive \
             --links \
             --times \
             --perms \
             --delete \
             --chmod=D755 --chmod=F644 \
             --files-from=- \
             $(CURDIR)/ \
             $(1)/
endef

define make_tarball
@echo "  TARBALL $(strip $(1))"
$(Q)$(TAR) -C $(dir $(2)) -cJf $(1) $(notdir $(2))
endef

distdir := $(BUILDDIR)/ebuild-$(VERSION)
dist: doc
	$(call sync_src_recipe,$(distdir))
	$(call installdir_recipe,--chmod=D755 --chmod=F644, \
	                         $(sphinxhtmldir), \
	                         $(distdir)/docs/html)
	$(foreach f, \
	          $(sphinx_list_pdf), \
	          $(call install_recipe, \
	                 -m644, \
	                 $(sphinxpdfdir)/$(f), \
	                 $(distdir)/docs/$(f))$(newline))
	$(foreach f, \
	          $(sphinx_list_info), \
	          $(call install_recipe,-m644, \
	                                $(sphinxinfodir)/$(f), \
	                                $(distdir)/docs/$(f))$(newline))
	$(call make_tarball,$(BUILDDIR)/ebuild-$(VERSION).tar.xz,$(distdir))

.PHONY: distclean
distclean: clean
