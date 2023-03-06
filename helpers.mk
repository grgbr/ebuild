ifndef V
.SILENT:
MAKEFLAGS += --no-print-directory
Q         := @
endif

empty  :=
space  := $(empty) $(empty)
squote := '

# Escape message given in argument for echo'ing to the console
# $(1): (unescaped) message to print
#
# Message will be escaped as required for echo'ing to the console according to
# bash(1) single quoted string escaping rules.
# See bash(1) "QUOTING" section.
define escape_shell_string
$(subst $(squote),\$(squote),$(1))
endef

# Print multi-line message given in argument to the console
# $(1): (unescaped) message to print
#
# Message will be escaped as required for echo'ing to the console.
# Recipes calling this macro MUST run a shell that understands bash(1) single
# quoted string escaping rules.
# See macro escape_shell_string().
define echo_multi_line
$(ECHOE) $$'$(subst $(newline),\n,$(call escape_shell_string,$(1)))'
endef

define newline
$(empty)
$(empty)
endef

define toupper
$(shell echo '$(1)' | tr '[:lower:]' '[:upper:]')
endef

define rm_recipe
@echo "  RM      $(1)"
$(Q)$(RM) $(1)
endef

define rmr_recipe
@echo "  RMR     $(1)"
$(Q)$(RM) -r $(1)
endef

define ln_recipe
@echo "  LN      $(2)"
$(Q)$(LN) -s $(1) $(2)
endef

define kconf_is_enabled
$(strip $(filter __y__,__$(subst $(space),,$(strip $(CONFIG_$(strip $(1)))))__))
endef

define kconf_enabled
$(strip $(if $(call kconf_is_enabled,$(1)),$(strip $(2)),$(strip $(3))))
endef

define kconf_disabled
$(strip $(if $(call kconf_is_enabled,$(1)),$(strip $(3)),$(strip $(2))))
endef

define pkgconfig_cmd
$(shell env PKG_CONFIG_LIBDIR="$(PKG_CONFIG_LIBDIR)" \
            PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
            PKG_CONFIG_SYSROOT_DIR="$(PKG_CONFIG_SYSROOT_DIR)" \
            $(PKG_CONFIG) $(1))
endef

define pkgconfig_cflags
$(if $(1),$(call pkgconfig_cmd,--cflags $(1)))
endef

define pkgconfig_ldflags
$(if $(1),$(call pkgconfig_cmd,--libs $(1)))
endef

# $(1): prerequisite object pathname
# $(2): final object pathname
define obj_cflags
$(strip $(if $($(subst $(BUILDDIR)/,,$(1))-cflags), \
             $($(subst $(BUILDDIR)/,,$(1))-cflags), \
             $($(2)-cflags)) \
             $(call pkgconfig_cflags,$($(2)-pkgconf)))
endef

define link_ldflags
$(strip $($(1)-ldflags) $(call pkgconfig_ldflags,$($(1)-pkgconf)))
endef

define obj_includes
$(strip $(if $(kconf_head),-I$(abspath $(kconf_head)/../..)) \
        -I$(dir $(1)) \
        -I$(dir $(2)) \
        $(if $(HEADERDIR),-I$(HEADERDIR)))
endef

define clean_recipe
$(foreach l, \
          $(1), \
          $(foreach o, \
                    $($(l)-objs) \
                    $(patsubst %.o,%.d,$($(l)-objs)) \
                    $(patsubst %.o,%.gcno,$($(l)-objs)) \
                    $(patsubst %.o,%.gcda,$($(l)-objs)), \
                    $(call rm_recipe,$(BUILDDIR)/$(o))$(newline)) \
          $(call rm_recipe,$(BUILDDIR)/$(l))$(newline))
endef

define strip_solib_recipe
@echo "  STRIP   $(1)"
$(Q)$(STRIP) --strip-unneeded $(1)
endef

define strip_bin_recipe
@echo "  STRIP   $(1)"
$(Q)$(STRIP) --strip-all $(1)
endef

define install_recipe
@echo "  INSTALL $(3)"
$(Q)mkdir -p -m755 $(dir $(3))
$(Q)$(INSTALL) $(1) $(2) $(3)
endef

define uninstall_recipe
$(foreach f,$(addprefix $(1)/,$(2)),$(call rm_recipe,$(f))$(newline))
endef

define has_cmd
$(shell type $(1) 2>/dev/null && echo y)
endef

# Run doxygen
# $(1): pathname to Doxyfile
# $(2): pathname to generated documentation base output directory
# $(3): additional environment variables given to doxygen
define doxy_recipe
@echo "  DOXY    $(2)"
$(Q)env OUTDIR="$(strip $(2))" $(3) $(if $(Q),QUIET="YES",QUIET="NO") \
        $(DOXY) \
        $(1)
endef

# Run sphinx-build to generate HTML
# $(1): pathname to sphinx documentation source directory
# $(2): pathname to generated HTML documentation output directory
# $(3): pathname to sphinx cache directory
# $(4): additional environment variables given to sphinx-build
define sphinx_html_recipe
@echo "  HTML    $(2)"
$(Q)$(if $(4),env $(4)) \
    $(SPHINXBUILD) -b html \
                   "$(strip $(1))" \
                   "$(strip $(2))" \
                   $(if $(Q),-Q,-q) \
                   -d "$(strip $(3))" \
                   -a \
                   -E \
                   -j auto
endef

# Run sphinx-build to generate PDF
# $(1): pathname to sphinx documentation source directory
# $(2): pathname to generated PDF documentation output directory
# $(3): pathname to sphinx cache directory
# $(4): additional environment variables given to sphinx-build
define sphinx_pdf_recipe
@echo "  LATEX   $(2)"
$(Q)$(if $(4),env $(4)) \
    $(SPHINXBUILD) -b latex \
                   "$(strip $(1))" \
                   "$(strip $(2))" \
                   $(if $(Q),-Q,-q) \
                   -d "$(strip $(3))" \
                   -a \
                   -E \
                   -j auto
@echo "  PDF     $(2)"
+$(Q)$(MAKE) --directory "$(strip $(2))" \
             all-pdf \
             LATEXMKOPTS='-interaction=nonstopmode -halt-on-error' \
             $(if $(Q),>/dev/null 2>&1)
endef


.DEFAULT_GOAL := build

.SUFFIXES:
