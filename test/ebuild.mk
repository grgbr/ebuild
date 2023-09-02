################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

define test_pkgconfig_tmpl
prefix=$(PREFIX)
exec_prefix=$${prefix}
libdir=$${exec_prefix}/lib

Name: libtest
Description: Ebuild test library
Version: %%PKG_VERSION%%
Requires:
Cflags: -rdynamic
Libs: -rdynamic -L$${libdir} -Wl,--no-as-needed,-lbtrace,--as-needed
endef

arlibs                     := libtest.a
libtest.a-cflags           := -Wall -Wextra -D_GNU_SOURCE
libtest.a-objs             := static/prereq_one.o static/prereq_two.o
static/prereq_one.o-cflags := -O3 $(libtest.a-cflags)

solibs                     := libtest.so
libtest.so-cflags          := -Wall -Wextra -D_GNU_SOURCE -fpic
libtest.so-ldflags         := -shared -fpic -Wl,-soname,libtest.so
libtest.so-objs            := shared/prereq_one.o shared/prereq_two.o
shared/prereq_one.o-cflags := -O4 $(libtest.so-cflags)

pkgconfigs                 := libtest.pc
libtest.pc-tmpl            := test_pkgconfig_tmpl

headers                    := ebuild/test.h

bins                       := test
test-cflags                := -Wall -Wextra -D_GNU_SOURCE
test-ldflags               := -ltest
test-objs                  := main.o

config-in                  := Config.in
config-h                   := ebuild/config.h
