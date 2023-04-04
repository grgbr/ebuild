################################################################################
# Build handling
################################################################################

define get_obj_src
$(if $($(1)-src),$($(1)-src),$(SRCDIR)/$(patsubst %.o,%.c,$(1)))
endef

define gen_obj_rule
$(BUILDDIR)/$(1): $(call get_obj_src,$(notdir $(strip $(1)))) \
                  $(all_deps) \
                  | $(dir $(BUILDDIR)/$(1)) $(addprefix build-,$(subdirs))
	@echo "  CC      $$(@)"
	$(Q)$(CC) $$(call obj_includes,$$(@),$$(<)) \
	          -MD -g $(call obj_cflags,$(1),$(2)) -o $$(@) -c $$(<)
endef

define gen_arlib_rule
$(BUILDDIR)/$(1): $(addprefix $(BUILDDIR)/,$($(1)-objs))
	$(if $($(1)-objs),,$$(error Missing '$(1)' build objects declaration !))
	@echo "  AR      $$(@)"
	$(Q)$(AR) rcs $$(@) $$(^)

$(foreach o,$($(1)-objs),$(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_solib_rule
$(BUILDDIR)/$(1): $(addprefix $(BUILDDIR)/,$($(1)-objs))
	$(if $($(1)-objs),,$$(error Missing '$(1)' build objects declaration !))
	@echo "  LD      $$(@)"
	$(Q)$(LD) -o $$(@) $$(^) -L$(BUILDDIR) $(call link_ldflags,$(1))

$(foreach o,$($(1)-objs),$(call gen_obj_rule,$(o),$(1))$(newline))
endef

define gen_pkgconfig_rule
$(BUILDDIR)/$(1): $(all_deps) | $(BUILDDIR)
	$(if $($(1)-tmpl), \
	     , \
	     $$(error Missing '$(1)' pkgconfig template declaration !))
	@echo "  PKGCFG  $$(@)"
	$(Q)/bin/echo -e '$$(subst $$(newline),\n,$$($($(1)-tmpl)))' > $$(@)
endef

define gen_bin_rule
$(BUILDDIR)/$(1): $(addprefix $(BUILDDIR)/,$($(1)-objs)) \
                  $(addprefix $(BUILDDIR)/,$(builtins)) \
                  $(addprefix $(BUILDDIR)/,$(solibs)) \
                  $(addprefix $(BUILDDIR)/,$(arlibs))
	@echo "  LD      $$(@)"
	$(Q)$(LD) -o $$(@) \
	          $(addprefix $(BUILDDIR)/,$($(1)-objs)) \
	          -L$(BUILDDIR) $(call link_ldflags,$(1))

$(foreach o,$($(1)-objs),$(call gen_obj_rule,$(o),$(1))$(newline))
endef

define make_subdir_cmd
$$(MAKE) --directory $(CURDIR)/$(2) \
         --makefile $(EBUILDDIR)/subdir.mk \
         $(1) \
         BUILDDIR:="$(BUILDDIR)/$(2)" \
         kconf_autoconf:="$(kconf_autoconf)" \
         kconf_head:="$(kconf_head)"
endef

define gen_subdir_rule
.PHONY: build-$(1)
build-$(1): $(addprefix build-,$($(1)-deps)) $(kconf_head)
	$(Q)$(call make_subdir_cmd,build,$(1))

.PHONY: clean-$(1)
clean-$(1):
	$(Q)$(call make_subdir_cmd,clean,$(1))

.PHONY: install-$(1)
install-$(1): $(addprefix install-,$($(1)-deps)) $(kconf_head)
	$(Q)$(call make_subdir_cmd,install,$(1))

.PHONY: uninstall-$(1)
uninstall-$(1): $(addprefix uninstall-,$($(1)-deps))
	$(Q)$(call make_subdir_cmd,uninstall,$(1))
endef

override build_prereqs := $(addprefix build-,$(subdirs)) \
                          $(addprefix $(BUILDDIR)/,$(builtins) \
                                                   $(arlibs) \
                                                   $(solibs) \
                                                   $(pkgconfigs) \
                                                   $(bins))

.PHONY: build
build: $(build_prereqs)

$(eval $(foreach d,$(subdirs),$(call gen_subdir_rule,$(d))$(newline)))

$(eval $(foreach l,$(arlibs),$(call gen_arlib_rule,$(l))$(newline)))

$(eval $(foreach l,$(builtins),$(call gen_arlib_rule,$(l))$(newline)))

$(eval $(foreach l,$(solibs),$(call gen_solib_rule,$(l))$(newline)))

$(eval $(foreach p,$(pkgconfigs),$(call gen_pkgconfig_rule,$(p))$(newline)))

$(eval $(foreach b,$(bins),$(call gen_bin_rule,$(b))$(newline)))

################################################################################
# Clean handling
################################################################################

.PHONY: clean
clean: $(addprefix clean-,$(subdirs))
	$(call clean_recipe,$(builtins) \
	                    $(arlibs) \
	                    $(solibs) \
	                    $(pkgconfigs) \
	                    $(bins))

################################################################################
# Install handling
################################################################################

define bin_install_path
$(DESTDIR)$(if $($(1)-path),$($(1)-path),$(BINDIR)/$(1))
endef

define install_bin_rule
$(call bin_install_path,$(1)): $(BUILDDIR)/$(1)
	$$(call install_recipe,-m755,$$(<),$$(@))

install: $(call bin_install_path,$(1))
endef

define solib_install_path
$(DESTDIR)$(if $($(1)-path),$($(1)-path),$(LIBDIR)/$(1))
endef

define install_solib_rule
$(call solib_install_path,$(1)): $(BUILDDIR)/$(1)
	$$(call install_recipe,-m755,$$(<),$$(@))

install: $(call solib_install_path,$(1))
endef

.PHONY: install
install: $(addprefix install-,$(subdirs)) \
         $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)) \
         $(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)) \
         $(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs))

$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)): \
	$(DESTDIR)$(INCLUDEDIR)/%: $(HEADERDIR)/% $(all_deps)
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)): \
	$(DESTDIR)$(LIBDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs)): \
	$(DESTDIR)$(PKGCONFIGDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(eval $(foreach b,$(solibs),$(call install_solib_rule,$(b))$(newline)))

$(eval $(foreach b,$(bins),$(call install_bin_rule,$(b))$(newline)))

ifdef config-in

install: $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h))

$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h)): $(all_deps)
	$(call install_recipe,-m644,$(<),$(@))

endif # config-in

.PHONY: install-strip
install-strip: install
	$(foreach b, \
	          $(solibs), \
	          $(call strip_solib_recipe, \
	          $(call solib_install_path,$(b)))$(newline))
	$(foreach b, \
	          $(bins), \
	          $(call strip_bin_recipe, \
	          $(call bin_install_path,$(b)))$(newline))

################################################################################
# Uninstall handling
################################################################################

.PHONY: uninstall
uninstall: $(addprefix uninstall-,$(subdirs))
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

-include $(wildcard $(BUILDDIR)/*.d)
