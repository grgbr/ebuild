################################################################################
# SPDX-License-Identifier: GPL-3.0-only
#
# This file is part of eBuild.
# Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
################################################################################

ifeq ($(strip $(PACKAGE)),)
$(error Missing PACKAGE definition !)
endif
export PACKAGE

export CROSS_COMPILE :=
export DESTDIR       :=
export PREFIX        := /usr/local
export SYSCONFDIR    := $(abspath $(PREFIX)/etc)
export INCLUDEDIR    := $(abspath $(PREFIX)/include)
export BINDIR        := $(abspath $(PREFIX)/bin)
export SBINDIR       := $(abspath $(PREFIX)/sbin)
export LIBDIR        := $(abspath $(PREFIX)/lib)
export LIBEXECDIR    := $(abspath $(PREFIX)/libexec)
export PKGCONFIGDIR  := $(abspath $(LIBDIR)/pkgconfig)
export LOCALSTATEDIR := $(abspath $(PREFIX)/var)
export RUNSTATEDIR   := $(abspath $(PREFIX)/run)
export DATADIR       := $(abspath $(PREFIX)/share)
export DOCDIR        := $(abspath $(DATADIR)/doc)
export INFODIR       := $(abspath $(DATADIR)/info)
export MANDIR        := $(abspath $(DATADIR)/man)

export CC            := $(CROSS_COMPILE)gcc
export AR            := $(CROSS_COMPILE)gcc-ar
export LD            := $(CROSS_COMPILE)gcc
export STRIP         := $(CROSS_COMPILE)strip
export ECHOE         := /bin/echo -e
export RM            := rm -f
export LN            := ln -f
export PKG_CONFIG    := pkg-config
export INSTALL       := install
export RSYNC         := rsync
export KCONF         := kconfig-conf
export KMCONF        := kconfig-mconf
export KXCONF        := kconfig-qconf
export KGCONF        := kconfig-gconf
export KNCONF        := kconfig-nconf
export DOXY          := doxygen
export PYTHON        := python3
export SPHINXBUILD   := sphinx-build
export LATEXMK       := latexmk
export MAKEINFO      := makeinfo
export INSTALL_INFO  := install-info
export GIT           := git
export SVN           := svn
export TAR           := tar

override TOPDIR      := $(CURDIR)
export TOPDIR

DEFCONFIG            :=
SRCDIR               := $(CURDIR)
HEADERDIR            := $(CURDIR)
BUILDDIR             := $(CURDIR)/build
