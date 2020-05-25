# Declare user specific rules and definitions.
ebuild_mkfile := $(CURDIR)/ebuild.mk

# Declare basic dependencies (most of) all make targets will depend on.
# See rules.mk to see how these are used as prerequisites.
all_deps := $(ebuild_mkfile) \
            $(EBUILDDIR)/subdir.mk \
            $(EBUILDDIR)/helpers.mk \
            $(EBUILDDIR)/rules.mk

# Pathname to directory where source files are located.
SRCDIR := $(CURDIR)

# Pathname to directory where installable headers are located.
# Defaults to current directory but may be overriden by user specific rules and
# definitions.
HEADERDIR := $(CURDIR)

# Include utility macros and definitions.
include $(EBUILDDIR)/helpers.mk

# If project has declared a build configuration :
# * include build configuration items using file pointed to by
#   $(kconf_autoconf) ;
# * augment basic dependencies $(all_deps) with pathname to top-level generated
#   configuration header $(kconf_head).
ifneq ($(strip $(kconf_autoconf)),)

ifeq ($(strip $(kconf_head)),)
$(error Missing subdir kconf_head definition !)
endif # ($(strip $(kconf_head)),)

all_deps += $(kconf_head) $(kconf_autoconf)

include $(kconf_autoconf)

endif # ifneq ($(strip $(kconf_autoconf)),)

# Include user specific rules and definitions.
include $(ebuild_mkfile)

# Finally include generic rules and definitions.
include $(EBUILDDIR)/rules.mk
