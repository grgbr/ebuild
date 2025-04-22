#!/bin/sh -e
################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

usage() {
	echo "Usage: $(basename $0) [KCONF_PATH]" >&2
	exit 1
}


kconf_path="-"
if test $# -gt 0; then
	kconf_path="$1"
	shift
fi
if test $# -gt 0 -o ! -r "$kconf_path"; then
	usage
fi

cat - << _EOF
#define __EBUILD_CONFIG_SECTION \
	".eBuild.config,\"MS\",@progbits,1#"

#define EBUILD_CONFIG(_var) \
	const char _var[] __attribute__((section(__EBUILD_CONFIG_SECTION), \
	                                 used))

static EBUILD_CONFIG(__ebuild_config) =
$(sed --silent \
      --expression='/^# Automatically generated file; DO NOT EDIT.$/d' \
      --expression='/^# Configuration$/d' \
      --expression=':p; /^[#]*$/d; s/\\/\\\\/g; s/"/\\"/g; s/^\(.*\)$/"\1\\0"/p; n; bp' \
      $kconf_path)
;
_EOF
