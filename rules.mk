################################################################################
# Build handling
################################################################################

define gen_obj_rule
$(BUILDDIR)/$(1): $(SRCDIR)/$(patsubst %.o,%.c,$(notdir $(1))) \
                  $(all_deps) \
                  | $(dir $(BUILDDIR)/$(1))
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

.PHONY: build
build: $(addprefix build-,$(subdirs)) \
       $(addprefix $(BUILDDIR)/,$(arlibs)) \
       $(addprefix $(BUILDDIR)/,$(solibs)) \
       $(addprefix $(BUILDDIR)/,$(pkgconfigs)) \
       $(addprefix $(BUILDDIR)/,$(bins))

$(eval $(foreach d,$(subdirs),$(call gen_subdir_rule,$(d))$(newline)))

$(eval $(foreach l,$(arlibs),$(call gen_arlib_rule,$(l))$(newline)))

$(eval $(foreach l,$(solibs),$(call gen_solib_rule,$(l))$(newline)))

$(eval $(foreach p,$(pkgconfigs),$(call gen_pkgconfig_rule,$(p))$(newline)))

$(eval $(foreach b,$(bins),$(call gen_bin_rule,$(b))$(newline)))

################################################################################
# Clean handling
################################################################################

.PHONY: clean
clean: $(addprefix clean-,$(subdirs))
	$(call clean_recipe,$(arlibs) $(solibs) $(pkgconfigs) $(bins))

################################################################################
# Install handling
################################################################################

.PHONY: install
install: $(addprefix install-,$(subdirs)) \
         $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)) \
         $(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)) \
         $(addprefix $(DESTDIR)$(LIBDIR)/,$(solibs)) \
         $(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs)) \
         $(addprefix $(DESTDIR)$(BINDIR)/,$(bins))

$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(headers)): \
	$(DESTDIR)$(INCLUDEDIR)/%: $(HEADERDIR)/% $(all_deps)
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(LIBDIR)/,$(arlibs)): \
	$(DESTDIR)$(LIBDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(LIBDIR)/,$(solibs)): \
	$(DESTDIR)$(LIBDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m755,$(<),$(@))

$(addprefix $(DESTDIR)$(PKGCONFIGDIR)/,$(pkgconfigs)): \
	$(DESTDIR)$(PKGCONFIGDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m644,$(<),$(@))

$(addprefix $(DESTDIR)$(BINDIR)/,$(bins)): \
	$(DESTDIR)$(BINDIR)/%: $(BUILDDIR)/%
	$(call install_recipe,-m755,$(<),$(@))

ifdef config-in

install: $(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h))

$(addprefix $(DESTDIR)$(INCLUDEDIR)/,$(config-h)): $(all_deps)
	$(call install_recipe,-m644,$(<),$(@))

endif # config-in

.PHONY: install-strip
install-strip: install
	$(foreach l, \
	          $(addprefix $(DESTDIR)$(LIBDIR)/,$(solibs)), \
	          $(call strip_lib_recipe,$(l))$(newline))
	$(foreach b, \
	          $(addprefix $(DESTDIR)$(BINDIR)/,$(bins)), \
	          $(call strip_bin_recipe,$(b))$(newline))

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
	$(call uninstall_recipe,$(DESTDIR)$(LIBDIR),$(solibs))
	$(call uninstall_recipe,$(DESTDIR)$(PKGCONFIGDIR),$(pkgconfigs))
	$(call uninstall_recipe,$(DESTDIR)$(BINDIR),$(bins))

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
