################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

################################################################################
# Source code tags generation handling
################################################################################

ifeq ($(call has_cmd,$(CTAGS))$(call has_cmd,$(CSCOPE)),nn)
$(error Neither ctags nor cscope found ! Setup $$(CTAGS) and/or $$(CSCOPE) \
        to generate source code tags)
endif # ($(call has_cmd,$(CTAGS))$(call has_cmd,$(CSCOPE)),nn)

.PHONY: tags
tags:

ifeq ($(call has_cmd,$(CTAGS)),y)

override ctagsfile := $(BUILDDIR)/tags
ctagsopts          ?= -F -B

.PHONY: ctags
ctags: | $(BUILDDIR)
	@echo "  CTAGS   $(ctagsfile)"
	$(Q)env CTAGS= $(CTAGS) $(ctagsopts) -f $(ctagsfile) $(tagfiles)

tags: ctags

endif # ($(call has_cmd,$(CTAGS)),y)

ifeq ($(call has_cmd,$(CSCOPE)),y)

override cscopefile := $(BUILDDIR)/cscope.out
cscopeopts          ?= -b -q -u

.PHONY: cscope
cscope: | $(BUILDDIR)
	@echo "  CSCOPE  $(cscopefile)"
	$(Q)$(CSCOPE) $(cscopeopts) -f$(cscopefile) $(tagfiles)

tags: cscope

endif # ($(call has_cmd,$(CSCOPE)),y)

clean: clean-tags

.PHONY: clean-tags
clean-tags:
	$(call rm_recipe,$(ctagsfile))
	$(call rm_recipe,$(cscopefile)*)
