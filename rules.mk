################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

################################################################################
# Build handling
################################################################################

define decl_error
$$(error Missing '$(1)' build $(2) declaration !)
endef

define check_obj_lot_decl
$(if $($(1)-objs)$($(1)-lots),,$(call decl_error,$(1),objects and/or lots))
endef

define get_obj_src
$(if $($(1)-src),$($(1)-src),$(SRCDIR)/$(patsubst %.o,%.c,$(1)))
endef

define get_obj_targets
$(filter-out $(config-obj),$($(1)-objs))
endef

define get_obj_paths
$(addprefix $(BUILDDIR)/,$(call get_obj_targets,$(1))) \
$(filter $(config-obj),$($(1)-objs))
endef

define get_lot_paths
$(addprefix $(BUILDDIR)/,$($(1)-lots))
endef

define gen_obj_rule
-include $(BUILDDIR)/$$(patsubst %.o,%.d,$(1))

$(BUILDDIR)/$(1): $(call get_obj_src,$(notdir $(1))) \
                  $(all_deps) \
                  | $(dir $(BUILDDIR)/$(1)) $(addprefix build-,$(subdirs))
	@echo "  CC      $$(@)"
	$(Q)$(CC) $$(call obj_includes,$$(@),$$(<)) \
	          -g $(call obj_cflags,$(1),$(2)) -MD -o $$(@) -c $$(<)
endef

define gen_builtin_rule
$(call get_lot_paths,$(1)): | $(dir $(BUILDDIR)/$(1)) \
                              $(addprefix build-,$(subdirs))

$(BUILDDIR)/$(1): $(call get_obj_paths,$(1)) $(call get_lot_paths,$(1))
	$(call check_obj_lot_decl,$(1))
	@echo "  AR      $$(@)"
	$(Q)$(RM) $$(@)
	$(Q)$(AR) rcsTP $$(@) $$(^)

$(foreach o, \
          $(call get_obj_targets,$(1)), \
          $(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_builtin_paths
$(if $(strip $(builtins)),$(addprefix $(BUILDDIR)/,$(builtins)))
endef

define gen_arlib_rule
$(call get_lot_paths,$(1)): | $(dir $(BUILDDIR)/$(1)) \
                              $(addprefix build-,$(subdirs))

$(BUILDDIR)/$(1): $(call get_obj_paths,$(1)) \
                  $(call get_lot_paths,$(1)) \
                  $(gen_builtin_paths)
	$(call check_obj_lot_decl,$(1))
	@echo "  AR      $$(@)"
	$(Q)$(RM) $$(@)
	$(Q)$(AR) rcs $$(@) $$(filter-out $(gen_builtin_paths),$$(^))

$(foreach o, \
          $(call get_obj_targets,$(1)), \
          $(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_solib_rule
$(call get_lot_paths,$(1)): | $(dir $(BUILDDIR)/$(1)) \
                              $(addprefix build-,$(subdirs))

$(BUILDDIR)/$(1): $(call get_obj_paths,$(1)) \
                  $(call get_lot_paths,$(1)) \
                  $(gen_builtin_paths)
	$(call check_obj_lot_decl,$(1))
	@echo "  LD      $$(@)"
	$(Q)$(LD) -o $$(@) \
	          $$(filter-out $(gen_builtin_paths),$$(^)) \
	          -L$(BUILDDIR) \
	          $(call link_ldflags,$(1))

$(foreach o, \
          $(call get_obj_targets,$(1)), \
          $(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_pkgconfig_rule
$(BUILDDIR)/$(1): $(all_deps) | $(BUILDDIR)
	$(if $($(1)-tmpl),,$(call decl_error,$(1),pkgconfig template))
	@echo "  PKGCFG  $$(@)"
	$(Q)/bin/echo -e '$$(subst $$(newline),\n,$$($($(1)-tmpl)))' > $$(@)
endef

define gen_bin_rule
$(call get_lot_paths,$(1)): | $(dir $(BUILDDIR)/$(1)) \
                              $(addprefix build-,$(subdirs))

$(BUILDDIR)/$(1): $(call get_obj_paths,$(1)) \
                  $(call get_lot_paths,$(1)) \
                  $(gen_builtin_paths) \
                  $(addprefix $(BUILDDIR)/,$(solibs)) \
                  $(addprefix $(BUILDDIR)/,$(arlibs))
	$(call check_obj_lot_decl,$(1))
	@echo "  LD      $$(@)"
	$(Q)$(LD) -o $$(@) \
	          $(call get_obj_paths,$(1)) \
	          $(call get_lot_paths,$(1)) \
	          -L$(BUILDDIR) $(call link_ldflags,$(1))

$(foreach o, \
          $(call get_obj_targets,$(1)), \
          $(call gen_obj_rule,$(o),$(1))$(newline))
endef

define make_subdir_cmd
$$(MAKE) --directory $(CURDIR)/$(2) \
         --makefile $(EBUILDDIR)/subdir.mk \
         $(1) \
         TOPDIR:="$(TOPDIR)" \
         BUILDDIR:="$(BUILDDIR)/$(2)" \
         PACKAGE:="$(PACKAGE)" \
         $(if $(VERSION),VERSION:="$(VERSION)") \
         kconf_autoconf:="$(kconf_autoconf)" \
         kconf_head:="$(kconf_head)" \
         config-obj:="$(config-obj)" \
         config-src:="$(config-src)"
endef

define gen_subdir_rule
.PHONY: build-$(1)
build-$(1): $(addprefix build-,$($(1)-deps)) $(kconf_head) $(config-obj)
	$(Q)$(call make_subdir_cmd,build,$(1))

.PHONY: build-check-$(1)
build-check-$(1): $(addprefix build-check-,$($(1)-deps)) \
                  $(kconf_head) \
                  $(config-obj)
	$(Q)$(call make_subdir_cmd,build-check,$(1))

.PHONY: clean-$(1)
clean-$(1):
	$(Q)$(call make_subdir_cmd,clean,$(1))

.PHONY: clean-check-$(1)
clean-check-$(1):
	$(Q)$(call make_subdir_cmd,clean-check,$(1))

.PHONY: install-$(1)
install-$(1): $(addprefix install-,$($(1)-deps)) $(kconf_head) $(config-obj)
	$(Q)$(call make_subdir_cmd,install,$(1))

.PHONY: install-strip-$(1)
install-strip-$(1): $(addprefix install-strip-,$($(1)-deps)) \
                    $(kconf_head) \
                    $(config-obj)
	$(Q)$(call make_subdir_cmd,install-strip,$(1))

.PHONY: install-check-$(1)
install-check-$(1): $(addprefix install-check-,$($(1)-deps)) \
                    $(kconf_head) \
                    $(config-obj)
	$(Q)$(call make_subdir_cmd,install-check,$(1))

.PHONY: install-strip-check-$(1)
install-strip-check-$(1): $(addprefix install-strip-check-,$($(1)-deps)) \
                          $(kconf_head) \
                          $(config-obj)
	$(Q)$(call make_subdir_cmd,install-strip-check,$(1))

.PHONY: uninstall-$(1)
uninstall-$(1):
	$(Q)$(call make_subdir_cmd,uninstall,$(1))

.PHONY: uninstall-check-$(1)
uninstall-check-$(1):
	$(Q)$(call make_subdir_cmd,uninstall-check,$(1))
endef

override build_prereqs := $(addprefix build-,$(subdirs)) \
                          $(addprefix $(BUILDDIR)/,$(builtins) \
                                                   $(arlibs) \
                                                   $(solibs) \
                                                   $(pkgconfigs) \
                                                   $(bins)) \
                          $(config-obj)

.PHONY: build
build: $(build_prereqs)

$(eval $(foreach d,$(subdirs),$(call gen_subdir_rule,$(d))$(newline)))

$(eval $(foreach l,$(arlibs),$(call gen_arlib_rule,$(l))$(newline)))

$(eval $(foreach l,$(builtins),$(call gen_builtin_rule,$(l))$(newline)))

$(eval $(foreach l,$(solibs),$(call gen_solib_rule,$(l))$(newline)))

$(eval $(foreach p,$(pkgconfigs),$(call gen_pkgconfig_rule,$(p))$(newline)))

$(eval $(foreach b,$(bins),$(call gen_bin_rule,$(b))$(newline)))

override build_check_prereqs := $(build_prereqs) \
                                $(addprefix build-check-,$(subdirs)) \
                                $(addprefix $(BUILDDIR)/,$(checkbins))

.PHONY: build-check
build-check: $(build_check_prereqs)

$(eval $(foreach b,$(checkbins),$(call gen_bin_rule,$(b))$(newline)))

################################################################################
# Clean handling
################################################################################

define clean_recipe
$(foreach l, \
          $(1), \
          $(foreach o, \
                    $(call get_obj_targets,$(l)) \
                    $(patsubst %.o,%.d,$(call get_obj_targets,$(l))) \
                    $(patsubst %.o,%.gcno,$(call get_obj_targets,$(l))) \
                    $(patsubst %.o,%.gcda,$(call get_obj_targets,$(l))), \
                    $(call rm_recipe,$(BUILDDIR)/$(o))$(newline)) \
          $(call rm_recipe,$(BUILDDIR)/$(l))$(newline))
endef

.PHONY: clean
clean: $(addprefix clean-,$(subdirs)) clean-check
	$(call clean_recipe,$(builtins) \
	                    $(arlibs) \
	                    $(solibs) \
	                    $(pkgconfigs) \
	                    $(bins))

.PHONY: clean-check
clean-check: $(addprefix clean-check-,$(subdirs))
	$(call clean_recipe,$(checkbins))

################################################################################
# Install handling
################################################################################

define bin_install_path
$(DESTDIR)$(if $($(1)-path),$($(1)-path),$(BINDIR)/$(1))
endef

define install_bin_rule
.PHONY: $(call bin_install_path,$(1))
$(call bin_install_path,$(1)): $(BUILDDIR)/$(1)
	$$(call install_recipe,-m755,$$(<),$$(@))

install install-strip: $(call bin_install_path,$(1))
endef

define solib_install_path
$(DESTDIR)$(if $($(1)-path),$($(1)-path),$(LIBDIR)/$(1))
endef

define install_solib_rule
.PHONY: $(call solib_install_path,$(1))
$(call solib_install_path,$(1)): $(BUILDDIR)/$(1)
	$$(call install_recipe,-m755,$$(<),$$(@))

install install-strip: $(call solib_install_path,$(1))
endef

.PHONY: install
install: $(addprefix install-,$(subdirs)) \
         $(gen_builtin_paths) \
         $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)) \
         $(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)) \
         $(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs))

.PHONY: $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers))
$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)): \
	$(DESTDIR)$(INCLUDEDIR)/%: $(HEADERDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

.PHONY: $(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs))
$(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)): \
	$(DESTDIR)$(LIBDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

.PHONY: $(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs))
$(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs)): \
	$(DESTDIR)$(PKGCONFIGDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(eval $(foreach b,$(solibs),$(call install_solib_rule,$(b))$(newline)))

$(eval $(foreach b,$(bins),$(call install_bin_rule,$(b))$(newline)))

ifdef config-in

install install-strip: $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h))

.PHONY: $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h))
$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h)): $(kconf_head)
	$(call install_recipe,-m644,$(<),$(@))

endif # config-in

.PHONY: install-strip
install-strip: $(addprefix install-strip-,$(subdirs)) \
               $(gen_builtin_paths) \
               $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)) \
               $(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)) \
               $(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs))
	$(foreach b, \
	          $(solibs), \
	          $(call strip_solib_recipe, \
	          $(call solib_install_path,$(b)))$(newline))
	$(foreach b, \
	          $(bins), \
	          $(call strip_bin_recipe, \
	          $(call bin_install_path,$(b)))$(newline))

define install_checkbin_rule
.PHONY: $(call bin_install_path,$(1))
$(call bin_install_path,$(1)): $(BUILDDIR)/$(1)
	$$(call install_recipe,-m755,$$(<),$$(@))

install-check install-strip-check: $(call bin_install_path,$(1))
endef

.PHONY: install-check
install-check: $(addprefix install-check-,$(subdirs)) build

$(eval $(foreach b,$(checkbins),$(call install_checkbin_rule,$(b))$(newline)))

.PHONY: install-strip-check
install-strip-check: $(addprefix install-strip-check-,$(subdirs)) build
	$(foreach b, \
	          $(checkbins), \
	          $(call strip_bin_recipe, \
	          $(call bin_install_path,$(b)))$(newline))

################################################################################
# Uninstall handling
################################################################################

.PHONY: uninstall
uninstall: $(addprefix uninstall-,$(subdirs)) uninstall-check
	$(call uninstall_recipe,$(DESTDIR)$(INCLUDEDIR),$(headers))
ifdef config-in
	$(call uninstall_recipe,$(DESTDIR)$(INCLUDEDIR),$(config-h))
endif # config-in
	$(call uninstall_recipe,$(DESTDIR)$(LIBDIR),$(arlibs))
	$(foreach l, \
	          $(solibs), \
	          $(call rm_recipe,$(call solib_install_path,$(l)))$(newline))
	$(call uninstall_recipe,$(DESTDIR)$(PKGCONFIGDIR),$(pkgconfigs))
	$(foreach b, \
	          $(bins), \
	          $(call rm_recipe,$(call bin_install_path,$(b)))$(newline))

.PHONY: uninstall-check
uninstall-check: $(addprefix uninstall-check-,$(subdirs))
	$(foreach b, \
	          $(checkbins), \
	          $(call rm_recipe,$(call bin_install_path,$(b)))$(newline))

################################################################################
# Various
################################################################################

$(BUILDDIR)/:
	@mkdir -p $(@)

ifdef config-in

$(dir $(kconf_head)):
	@mkdir -p $(@)

endif # config-in

$(BUILDDIR)/%/:
	@mkdir -p $(@)
