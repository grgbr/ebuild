################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

# Handle source distribution targets only when $(distfiles) is defined.
ifneq ($(strip $(distfiles)),)

override distname    := $(PACKAGE)-$(VERSION)
override distdir     := $(BUILDDIR)/$(distname)
override disttarball := $(BUILDDIR)/$(distname).tar.xz

define dist_ebuild_cmds :=
$(foreach f, \
          $(notdir $(wildcard $(EBUILDDIR)/*.mk)), \
          $(call install_recipe,--mode=644, \
                                $(EBUILDDIR)/$(f), \
                                $(distdir)/ebuild/$(f))$(newline))
$(foreach f, \
          $(notdir $(wildcard $(EBUILDDIR)/scripts/*)), \
          $(call install_recipe,--mode=644, \
                                $(EBUILDDIR)/scripts/$(f), \
                                $(distdir)/ebuild/scripts/$(f))$(newline))
endef

define dist_src_cmds
@echo "  SYNC    $(distdir)"
$(Q)mkdir -p -m755 $(distdir)
$(Q)$(ECHOE) "$(subst $(space),\n,$(1))" | \
    $(RSYNC) --recursive \
             --links \
             --times \
             --perms \
             --delete \
             --chmod=D755 \
             --chmod=F644 \
             --files-from=- \
             $(CURDIR)/ \
             $(distdir)/
endef

define dist_tar_cmd
@echo "  TARBALL $(disttarball)"
$(Q)$(TAR) --owner=1000 \
           --group=1000 \
           --directory $(dir $(distdir)) \
           -caf $(disttarball) \
           $(notdir $(distdir))
endef

.PHONY: dist
dist: $(doc_dist_targets)
	$(if $(strip $(distfiles)),,\
	             $(error Missing distribution files definition !))
	@$(RM) -r $(distdir)
	$(dist_ebuild_cmds)
	$(call dist_src_cmds,$(distfiles))
	$(doc_dist_cmds)
	$(dist_tar_cmd)

define _help_dist_target :=

  dist                -- build source distribution tarball
endef

endif # ifneq ($(strip $(distfiles)),)

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
ifneq ($(strip $(distfiles)),)
	$(call rmr_recipe,$(distdir))
	$(call rm_recipe,$(disttarball))
endif # ($(strip $(distfiles)),)

define help_dist_targets =


::Distribution::\
  $(_help_dist_target)
  distclean           -- run `clean' target, remove build configuration and
                         distribution tarball
endef
