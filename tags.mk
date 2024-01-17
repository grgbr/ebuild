################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

################################################################################
# Source code tags generation handling
################################################################################

# Handle source code tags targets only when $(tag-files) is defined.
ifneq ($(strip $(tagfiles)),)

.PHONY: tags
tags:

override ctagsfile := $(BUILDDIR)/tags
ctagsopts          ?= -F -B

.PHONY: ctags
ctags: | $(BUILDDIR)
	$(call has_cmd_or_die,CTAGS)
	@echo "  CTAGS   $(ctagsfile)"
	$(Q)env CTAGS= $(CTAGS) $(ctagsopts) -f $(ctagsfile) $(tagfiles)

tags: ctags

define help_ctags_var :=

  CTAGS         -- exuberant ctags source tags generator
                   [$(CTAGS)]
endef

override cscopefile := $(BUILDDIR)/cscope.out
cscopeopts          ?= -b -q -u

.PHONY: cscope
cscope: | $(BUILDDIR)
	$(call has_cmd_or_die,CSCOPE)
	@echo "  CSCOPE  $(cscopefile)"
	$(Q)$(CSCOPE) $(cscopeopts) -f$(cscopefile) $(tagfiles)

tags: cscope

clean: clean-tags

.PHONY: clean-tags
clean-tags:
	$(call rm_recipe,$(ctagsfile))
	$(call rm_recipe,$(cscopefile)*)

define help_cscope_var :=

  CSCOPE        -- cscope source tags generator
                   [$(CSCOPE)]
endef

define help_tags_targets :=


::Source tags::
  tags                -- build source tag databases
  clean-tags          -- remove built source tag databases
endef

define help_tags_vars :=


::Source tags::
  $(strip $(if $(call has_cmd,$(CSCOPE)),CSCOPE) \
          $(if $(call has_cmd,$(CTAGS)),CTAGS))
endef

endif # ifneq ($(strip $(tagfiles)),)
