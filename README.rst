.. SPDX-License-Identifier: GFDL-1.3-only

   This file is part of CUTe.
   Copyright (C) 2023 Grégor Boirie <gregor.boirie@free.fr>

.. _ebuild:                    https://github.com/grgbr/ebuild
.. _make:                      https://www.gnu.org/software/make/
.. _gnu makefile:              make_
.. _gnu:                       https://www.gnu.org/
.. _kbuild:                    https://www.kernel.org/doc/html/latest/kbuild/
.. _linux kernel build system: kbuild_
.. _pkg-config:                https://www.freedesktop.org/wiki/Software/pkg-config/
.. _autoconf:                  https://www.gnu.org/software/autoconf/
.. _kconfig:                   https://salsa.debian.org/philou/kconfig-frontends/
.. _sphinx:                    http://sphinx-doc.org/

About
#####

eBuild_ is a `GNU Makefile`_ based build system deeply inspired by the
`Linux kernel build system`_.

It is meant to ease the process of writing rules to build software in a concise
and flexible manner.
Although not restricted to, eBuild_ mainly focuses on building (and installing)
userland software for embedded systems.


.. rubric:: Features

* declarative build target definitions ;
* KConfig_ based build configuration support ;
* multi-level project hierarchy support ;
* cross build environment support ;
* eBuild_ logic may be embedded within project sources so that build
  requirements are restricted to make_ only ;
* Pkg-config_ support ;
* Sphinx_ based documentation generation ;
* parallel build support ;
* custom make_ rules support.
  
.. rubric:: Limitations

* no discovery of complex system-specific build and runtime informations
  (use Autoconf_ instead) ;
* compile and link logic limited to projects implemented using the C language ;
* restricted to GNU_ platforms.

.. rubric:: Licensing

eBUild_ is distributed under the `GNU General Public License
<https://www.gnu.org/licenses/gpl-3.0.html>`_.

Trivial Example
###############

To build a sample ``hello-world`` application, a typical ``ebuild.mk`` build
rules file would look like :

.. code-block:: make

   #
   # Declare common compile and link flags and provide the end-user with the
   # ability to extend them using the EXTRA_CFLAGS and EXTRA_LDFLAGS make
   # variables.
   #
   common-cflags       := -Wall -Wextra $(EXTRA_CFLAGS)
   common-ldflags      := $(common-cflags) $(EXTRA_LDFLAGS)
   
   #
   # What to build : declare the list of binaries to build and install
   #
   bins                += hello-world
   
   #
   # How to build: define the way to compile, link and install the
   # hello-world binary.
   #
   
   # hello-world is implemented using a single hello-world.c main source file.
   hello-world-objs    := hello-world.o
   # Compile hello-world using common compile flags.
   hello-world-cflags  := $(common-cflags)
   # Link hello-world using common link flags.
   hello-world-ldflags := $(common-ldflags)
   # Install hello-world under $(SBINDIR) instead of the default
   $(BINDIR) location.
   hello-world-path    := $(SBINDIR)/hello-world

Getting Help
############

`Latest documentation <https://grgbr.github.io/ebuild/>`_ is available online.

The `User guide <sphinx/user.rst>`_ documents how to **build and deploy software
projects** based upon eBuild_.

An *Install guide* and a *Programmer's guide* are currently in the process of
writing...
