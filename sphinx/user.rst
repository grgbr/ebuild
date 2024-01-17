.. SPDX-License-Identifier: GPL-3.0-only
   
   This file is part of eBuild.
   Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>

.. include:: _cdefs.rst

.. |Build|     replace:: :ref:`Build <sect-user-build>`
.. |Install|   replace:: :ref:`Install <sect-user-install>`
.. |DEFCONFIG| replace:: :ref:`DEFCONFIG <var-defconfig>`
.. |INSTALL|   replace:: :ref:`INSTALL <var-install>`

Overview
========

This guide mainly focuses upon how to build and deploy software projects which
build system is based upon |eBuild|.
This document mainly targets software package integration.

|eBuild| is distributed under the :ref:`GNU General Public License <gpl>`.

.. _sect-user-prerequisites:

Prerequisites
=============

.. rubric:: Minimal requirements

The following installed package is required to build |eBuild| based packages :

* |GNU make|.

.. rubric:: Documentation generation

In addition, you might need the following installed packages to build the
documentation :

* |Doxygen|,
* |Kconfiglib|,
* |LaTeX|,
* |Latexmk|,
* |Python| version 3,
* |Sphinx|,
* |Sphinx Read The Docs theme|,
* |Texinfo|,
* |Rsync|.

.. rubric:: Full-feature requirements

For a full-featured |eBuild| based package, the following is also required in
addition to the above :

* |KConfig|,
* |Pkg-config|,
* a compile and link toolchain such as |GNU Binutils| and |GNU GCC|,
* |Ctags| and / or |Cscope| source tag database tools,
* |XZ| compression tools.

.. _sect-user-workflow:

Workflow
========

The typical build and install workflow for a software project based upon
|eBuild| is the following:

#. Configure_ the construction logic
#. |Build| programs, libraries and other objects required at running time,
#. |Install| components, copying files previously built to system-wide
   directories

The 3 phases mentioned above are subject to customization thanks to multiple
:command:`make` variable settings that may be passed on the command line. *You
are encouraged to adjust values according to your specific needs*. Most of the
time, setting BUILDDIR_, PREFIX_ and CROSS_COMPILE_ is sufficient. Refer to the
following sections for further informations.

After a successful |Install| phase, final constructed objects are located under
the directory pointed to by ``$(DESTDIR)$(PREFIX)`` where DESTDIR_ and PREFIX_
are 2 :command:`make` variables the user may specify on the command line to
customize the final install location.

Alternatively, you are also provided with the ability to :

* build and install testing_ logic,
* cleanup_ generated objects,
* generate documentation_,
* generate `source tags`_,
* generate source distribution_ tarball.

To begin with, configure_ the build process according to the following section.

.. _sect-user-configure:

Configure
---------

To apply the project's **default build configuration**, run the following
command from the top-level project's source tree:

.. code-block:: console

   $ make defconfig

You may specify an alternate default build configuration file by giving
:command:`make` a |DEFCONFIG| variable which value points to an arbitrary file
path:

.. code-block:: console

   $ make defconfig DEFCONFIG=$HOME/build/config/project.defconfig

This alternate default build configuration file may be generated from current
configuration into the :file:`defconfig` file located under directory pointed to
by the BUILDDIR_ variable:

.. code-block:: console

   $ make saveconfig BUILDDIR=$HOME/build/project
     KSAVE   /home/worker/build/project/defconfig

Optionally, you may **tweak build options** interactively:

.. code-block:: console

   $ make menuconfig BUILDDIR=$HOME/build/project

The :ref:`menuconfig target <target-menuconfig>` runs a menu-driven
user interface allowing you to configure build options. You may run alternate
user interfaces using the following :command:`make` targets :

* xconfig_ for a QT menu-driven interface,
* and gconfig_ for GTK menu-driven interface.

The default build directory location is overwritten by giving :command:`make`
the BUILDDIR_ variable which value points to an arbitrary pathname. Intermediate
objects are built under the passed directory to prevent from polluting the
project's source tree as in the following example:

.. code-block:: console

   $ make defconfig BUILDDIR=$HOME/build/project

You may refine the configuration logic by giving :command:`make` additional
variables.  *You are encouraged to adjust values according to your specific
needs*. Section Variables_ describes the following variables which are available
for configuration customization purpose:

* EBUILDDIR_,
* |DEFCONFIG|,
* BUILDDIR_,
* KCONF_, KGCONF_, KMCONF_, KXCONF_,
* in addition to variables listed in the Tools_ section.

You may also customize tools used at configuration time. Refer to section Tools_
for more informations.

You can now proceed to the |Build| phase.

.. _sect-user-build:

Build
-----

To build / compile / link programs, libraries, etc., run the :command:`make`
command like so:

.. code-block:: console

   $ make build

To store intermediate objects under an alternate location, give :command:`make`
the BUILDDIR_ variable like so:

.. code-block:: console

   $ make build BUILDDIR=$HOME/build/project

If not completed, the ``build`` target performs the configuration phase
implicitly using default configuration settings.

In addition, you may specify the PREFIX_ variable to change the default final
install location:

.. code-block:: console

   $ make build BUILDDIR=$HOME/build/project PREFIX=/

You may refine the build logic by giving :command:`make` additional variables.
*You are encouraged to adjust values according to your specific needs*. Section
Reference_ describes the following variables which are available for build
customization purpose:

* EBUILDDIR_, |DEFCONFIG|, KCONF_,
* BUILDDIR_,
* PREFIX_, SYSCONFDIR_, BINDIR_, SBINDIR_, LIBDIR_, LIBEXECDIR_, LOCALSTATEDIR_,
  RUNSTATEDIR_, INCLUDEDIR_, PKGCONFIGDIR_, DATADIR_, DOCDIR_, INFODIR_,
  MANDIR_,
* CROSS_COMPILE_, AR_, CC_, LD_, PKG_CONFIG_,
* in addition to variables listed in the Tools_ section.

You may also customize tools used at build time. Refer to section Tools_ for
more informations.

You can now proceed to the |Install| phase.

.. _sect-user-install:

Install
-------

To install programs, libraries, etc., run the :command:`make` command like so:

.. code-block:: console

   $ make install

To store intermediate objects under an alternate location, give :command:`make`
the BUILDDIR_ variable like so:

.. code-block:: console

   $ make install BUILDDIR=$HOME/build/project

If not completed, the :ref:`install <target-install>` target performs the
|Build| phase implicitly.  Files are installed under directory pointed to by the
PREFIX_ :command:`make` variable which defaults to :file:`/usr/local`.

You may specify the PREFIX_ variable to change the default final install
location:

.. code-block:: console

   $ make install BUILDDIR=$HOME/build/project PREFIX=/

You may refine the install logic by giving :command:`make` additional variables.
*You are encouraged to adjust values according to your specific needs*. Section
Reference_ describes the following variables which are available for install
customization purpose:

* EBUILDDIR_, |DEFCONFIG|, KCONF_,
* BUILDDIR_,
* PREFIX_, SYSCONFDIR_, BINDIR_, SBINDIR_, LIBDIR_, LIBEXECDIR_, LOCALSTATEDIR_,
  RUNSTATEDIR_, INCLUDEDIR_, PKGCONFIGDIR_, DATADIR_,
* CROSS_COMPILE_, STRIP_,
* in addition to variables listed in the Tools_ section.

You may also customize tools used at install time. Refer to section Tools_ for
more informations.

.. _sect-user-staged-install:

Staged install
--------------

DESTDIR_ :command:`make` variable allows support for staged install, i.e. an
install workflow where files are deployed under an alternate top-level root
directory instead of the usual directory pointed to by PREFIX_.

Basically, the DESTDIR_ variable is prepended to each installed target file so
that an install recipe might look something like:

.. code-block:: make

   install:
        $(INSTALL) foo $(DESTDIR)$(BINDIR)/foo
        $(INSTALL) libfoo.a $(DESTDIR)$(LIBDIR)/libfoo.a

The DESTDIR_ variable should be specified by the user on the :command:`make`
command line as an absolute file name. For example:

.. code-block:: console

   $ make install DESTDIR=$HOME/staging

If usual installation step would normally install :file:`$(BINDIR)/foo` and
:file:`$(LIBDIR)/libfoo.a`, then an installation invoked as in the example above
would install :file:`$(HOME)/staging/$(BINDIR)/foo` and
:file:`$(HOME)/staging/$(LIBDIR)/libfoo.a` instead.

Prepending the variable DESTDIR_ to each target in this way provides for staged
installs, where the installed files are not placed directly into their expected
location but are instead copied into a temporary location (DESTDIR). However,
installed files maintain their relative directory structure and any embedded
file names will not be modified.

DESTDIR_ support is commonly used in package creation. It is also helpful to
users who want to understand what a given package will install where, and to
allow users who don’t normally have permissions to install into protected areas
to build and install before gaining those permissions.

Finally, it can be usefull when installing in a cross compile environment where
installation is performed according to a 2 stages process.
An initial stage installs files under a top-level root directory hierarchy
pointed to by the DESTDIR_ variable onto the development host. This step is
generally part of a larger process which constructs the whole final system image
to install onto the target host.
Then, the second stage carries out final system image installation onto the
target host thanks to a specific *installer* runtime that is out of scope of
this document.

Refer to |gnu_install_destdir| for more informations.

Cleanup
-------

3 additional :command:`make` targets are available to cleanup generated objects.

The :ref:`clean <target-clean>` target remove built objects from the BUILDDIR_
directory without cleaning up installed objects.
In other words, this performs the inverse operation of |Build| target:

.. code-block:: console

   $ make clean BUILDDIR=$HOME/build/project

The :ref:`distclean <target-distclean>` target runs
:ref:`clean <target-clean>` target then removes build configuration objects and
distribution_ tarball from the BUILDDIR_ directory.
In other words, this removes every intermediate objects, i.e., all generated
objects that have not been installed:

.. code-block:: console

   $ make distclean BUILDDIR=$HOME/build/project

The :ref:`uninstall <target-uninstall>` target removes
installed objects from the $(DESTDIR_)$(PREFIX_) directory.
In other words, this performs the inverse operation of |Install| target:

.. code-block:: console

   $ make uninstall PREFIX= DESTDIR=$HOME/staging

Documentation
-------------

When enabled internally by a project, |eBuild| may also generates project's
documentation thanks to (and restricted to) the |Sphinx| ecosystem.

Generation
**********

The :ref:`doc <target-doc>` :command:`make` target builds documentation under
:file:`$(BUILDDIR)/doc` directory :

.. code-block:: console

   $ make doc BUILDDIR=$HOME/build/project

In addition, objects generated by the :ref:`doc <target-doc>` target may be
removed using the :ref:`clean-doc <target-clean-doc>` or
:ref:`clean <target-clean>` target as described into section cleanup_.

You may refine the build logic by giving :command:`make` additional variables.
*You are encouraged to adjust values according to your specific needs*. Section
Reference_ describes the following variables which are available for
documentation generation customization purpose:

* BUILDDIR_,
* SPHINXBUILD_, PYTHON_, MAKEINFO_, LATEXMK_, DOXY_,
* in addition to variables listed in the Tools_ section.

Installation
************

To install documentation built thanks to :ref:`doc <target-doc>` target
under DOCDIR_ directory, use the :ref:`install-doc <target-install-doc>` target.

.. code-block:: console

   $ make install-doc BUILDDIR=$HOME/build/project

If not completed, the :ref:`install-doc <target-install-doc>` target builds the
documentation implicitly. Files are installed under directory pointed to by the
DOCDIR_ :command:`make` variable.

In addition, objects installed by the :ref:`install-doc <target-install-doc>`
target may be removed using the :ref:`uninstall-doc <target-uninstall-doc>` or
:ref:`uninstall <target-uninstall>` target as described into section cleanup_.

You may refine the documentation (un)install logic by giving :command:`make`
additional variables.  *You are encouraged to adjust values according to your
specific needs*. Section Reference_ describes the following variables which are
available for documentation generation customization purpose:

* PREFIX_,
* DATADIR_, DOCDIR_,
* MANDIR_, MANDB_,
* INSTALL_INFO_, INFODIR_.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final
documentation is deployed under $(DESTDIR_)$(DOCDIR_) filesystem hierarchy
instead.

.. _sect-user-testing:

Testing
-------

When enabled internally by a project, |eBuild| may also generates project's
test suites.

.. _sect-user-testing-generation:

Generation
**********

The :ref:`build-check <target-build-check>` :command:`make` target builds
testing objects under :file:`$(BUILDDIR)` directory :

.. code-block:: console

   $ make build-check BUILDDIR=$HOME/build/project

In addition, objects generated by the :ref:`build-check <target-build-check>`
target may be removed using the :ref:`clean-check <target-clean-check>` or
:ref:`clean <target-clean>` target as described into section cleanup_.

You may refine the build logic by giving :command:`make` additional variables.
*You are encouraged to adjust values according to your specific needs*. Section
Reference_ describes the following variables which are available for
documentation generation customization purpose:

* EBUILDDIR_, |DEFCONFIG|, KCONF_,
* BUILDDIR_,
* PREFIX_, SYSCONFDIR_, BINDIR_, SBINDIR_, LIBDIR_, LIBEXECDIR_, LOCALSTATEDIR_,
  RUNSTATEDIR_, INCLUDEDIR_, PKGCONFIGDIR_, DATADIR_
* CROSS_COMPILE_, AR_, CC_, LD_, PKG_CONFIG_,
* in addition to variables listed in the Tools_ section.

Installation
************

To install testing objects built thanks to the :ref:`build-check
<target-build-check>` target, use the :ref:`install-check <target-install-check>`
target:

.. code-block:: console

   $ make install-check BUILDDIR=$HOME/build/project

If not completed, the :ref:`install-check <target-install-check>` target
performs the :ref:`generation <sect-user-testing-generation>` phase implicitly.
Files are installed under directory pointed to by the PREFIX_ :command:`make`
variable which defaults to :file:`/usr/local`.

You may specify the PREFIX_ variable to change the default final install
location:

.. code-block:: console

   $ make install-check BUILDDIR=$HOME/build/project PREFIX=/

In addition, objects installed by the
:ref:`install-check <target-install-check>` target may be removed using the
:ref:`uninstall-check <target-uninstall-check>` or
:ref:`uninstall <target-uninstall>` target as described into section cleanup_.

You may refine the install logic by giving :command:`make` additional variables.
*You are encouraged to adjust values according to your specific needs*. See
section |Install| for additional details.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final testing
objects are deployed under $(DESTDIR_)$(DOCDIR_) filesystem hierarchy instead.

.. _sect-user-tags:

Source tags
-----------

A :ref:`tags <target-tags>` :command:`make` target is also available to generate
source code tag databases using |Ctags| and / or |Cscope| tools.

When available, |Ctags| database is generated into the
:file:`$(BUILDDIR)/tags` file whereas |Cscope| database is generated into
:file:`$(BUILDDIR)/cscope.out` file.

.. code-block:: console

   $ make tags BUILDDIR=$HOME/build/project

In addition, objects generated by the :ref:`tags <target-tags>` target may be
removed using the :ref:`clean-tags <target-clean-tags>` or
:ref:`clean <target-clean>` target as described into section cleanup_.

You may refine the build logic by giving :command:`make` additional variables.
*You are encouraged to adjust values according to your specific needs*. Section
Reference_ describes the following variables which are available for source tags
generation customization purpose:

* BUILDDIR_,
* CTAGS_, CSCOPE_.
* in addition to variables listed in the Tools_ section.

Distribution
------------

A :ref:`dist <target-dist>` :command:`make` target is also available to generate
a source distribution tarball compressed according to the |XZ| format into
:file:`$(BUILDDIR)/<package_name>-<package_version>.tar.xz`.

Basically, the :ref:`dist target <target-dist>` generates, collects and include
the following components into the tarball :

* files required to build the project when no |eBuild| installation is found ;
* project's files found under revision control ;
* if any, the project's documentation files.

.. code-block:: console

   $ make dist BUILDDIR=$HOME/build/project

In addition, objects generated by the :ref:`dist <target-dist>` target may be
removed using the :ref:`distclean <target-distclean>` target as described into
section cleanup_.

.. _sect-user-tools:

Tools
-----

You may customize tools used during construction phases by giving
:command:`make` additional variables like so:

.. code-block:: console

   $ make build CROSS_COMPILE='armv7-linaro-linux-gnueabihf-'

Section Variables_ describes the following variables which are available for
tool customization purpose:

* AR_,
* CROSS_COMPILE_,
* CSCOPE_,
* CTAGS_,
* CC_,
* DOXY_,
* ECHOE_,
* GIT_,
* |INSTALL|,
* INSTALL_INFO_,
* KCONF_,
* KMCONF_,
* KXCONF_,
* KGCONF_,
* LATEXMK_,
* MAKEINFO_,
* MANDB_,
* LD_,
* LN_,
* PKG_CONFIG_,
* PYTHON_,
* RM_,
* RSYNC_,
* SPHINXBUILD_,
* STRIP_,
* SVN_.

.. _sect-user-reference:

Reference
=========

Targets
-------

This section describes all :command:`make` targets that may be given on the
command line to run a particular construction phase.

.. _target-build:

build
*****

Compile / link objects. Built objects are stored under BUILDDIR_ directory.

If not completed, the build target performs the configuration phase implicitly
using default configuration settings.

Refer to section |Build| for a list of variables affecting this target
behavior.

.. _target-build-check:

build-check
***********

Compile / link testing objects. Built objects are stored under BUILDDIR_
directory.

If not completed, the build target performs the configuration phase implicitly
using default configuration settings.

Refer to section :ref:`Test generation <sect-user-testing-generation>` for a
list of variables affecting this target behavior.

.. _target-clean:

clean
*****

Remove built objects and documentation from the BUILDDIR_ directory.

Refer to sections |Build| and Tools_ for a list of variables affecting this
target behavior.

.. _target-clean-check:

clean-check
***********

Remove built testing objects from the $(BUILDDIR_) directory.

Refer to section Tools_ for a list of variables affecting this target behavior.

.. _target-clean-doc:

clean-doc
*********

Remove built documentation from the $(BUILDDIR_)/doc directory.

Refer to section Tools_ for a list of variables affecting this target behavior.

.. _target-clean-tags:

clean-tags
**********

Remove built tag databases from the BUILDDIR_ directory.

Refer to section Tools_ for a list of variables affecting this target behavior.

.. _target-defconfig:

defconfig
*********

Configure build using default settings. Created configuration objects are stored
under the BUILDDIR_ directory.

Refer to section Configure_ for a list of variables affecting this target
behavior.

.. _target-dist:

dist
****

Build source distribution_ tarball including :

* |eBuild| files required to build a project under :file:`ebuild` directory,
* project's documentation under :file:`docs` directory,
* project's files that are under revision control.

Tarball will be located under the BUILDDIR_ directory and named after the
following scheme : :file:`<package_name>-<package_version>.tar.xz`.

.. _target-distclean:

distclean
*********

Run :ref:`clean target <target-clean>` then remove build configuration objects
created by the build configuration and distribution_ targets from the BUILDDIR_
directory.

Refer to section Configure_ for a list of configuration targets variables
affecting this target behavior.

.. _target-doc:

doc
***

Build documentation under $(BUILDDIR_)/doc directory.

Refer to section Documentation_ for a list of variables affecting this target
behavior.

gconfig
*******

Edit build configuration using an interactive |GTK| menu-driven interface. 

An arbitrary file containing default options may be specified using |DEFCONFIG|
variable.
These default options are applied when no previous configuration target has been
run.

Refer to section Configure_ for a list of variables affecting this target
behavior.

.. _target-help:

help
****

Show a brief help message.

.. _target-help-full:

help-full
*********

Show a detailed help message.

.. _target-install:

install
*******

Install objects constructed at :ref:`building <sect-user-build>` time. Objects
are basically installed under PREFIX_ directory.

If not completed, the install target performs the build phase implicitly using
default configuration settings.

Refer to section |Install| for a list of variables affecting this target
behavior.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final objects are
deployed under :file:`$(DESTDIR)$(PREFIX)` instead.

.. _target-install-check:

install-check
*************

Install testing objects constructed at
:ref:`testing generation <sect-user-testing-generation>` time. Objects are
basically installed under PREFIX_ directory.

Refer to section |Install| for a list of variables affecting this target
behavior.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final testing
objects are deployed under :file:`$(DESTDIR)$(PREFIX)` instead.

.. _target-install-doc:

install-doc
***********

Install documentation built thanks to :ref:`doc <target-doc>` target under
DOCDIR_ directory.

Refer to section Documentation_ for a list of variables affecting this target
behavior.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final objects are
deployed under :file:`$(DESTDIR)$(DOCDIR)` instead.

install-strip
*************

Run :ref:`install target <target-install>` and discard symbols from installed
objects.

.. _target-menuconfig:

menuconfig
**********

Edit build configuration using an interactive |NCurses| menu-driven interface. 

An arbitrary file containing default options may be specified using |DEFCONFIG|
variable.
These default options are applied when no previous configuration target has been
run.

Refer to section Configure_ for a list of variables affecting this target
behavior.

saveconfig
**********

Save current build configuration into :file:`$(BUILDDIR)/defconfig` default
settings file that can be loaded using a subsequent :ref:`defconfig target
<target-defconfig>` run.

Refer to section Configure_ for a list of variables affecting this target
behavior.

.. _target-tags:

tags
****

Build source tag databases under BUILDDIR_ directory.

Refer to section `Source tags`_ for a list of variables affecting this target
behavior.

.. _target-uninstall:

uninstall
*********

Remove installed objects and documentation from the PREFIX_ directory.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final objects are
removed from the :file:`$(DESTDIR)$(PREFIX)` directory instead.

Refer to sections |Install| and Cleanup_ for a list of variables affecting this
target behavior.

.. _target-uninstall-check:

uninstall-check
***************

Remove installed testing objects from the PREFIX_ directory.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final testing
objects are removed from the :file:`$(DESTDIR)$(PREFIX)` directory instead.

Refer to sections |Install| and Cleanup_ for a list of variables affecting this
target behavior.

.. _target-uninstall-doc:

uninstall-doc
*************

Remove installed documentation from the DOCDIR_ directory.

In addition, when following a `Staged install`_ workflow, you may alter final
installation directory thanks to the DESTDIR_ variable so that final objects are
removed from the :file:`$(DESTDIR)$(DOCDIR)` directory instead.

Refer to sections Documentation_ and Cleanup_ for a list of variables affecting this
target behavior.

xconfig
*******

Edit build configuration using an interactive |QT| menu-driven interface. 

An arbitrary file containing default options may be specified using |DEFCONFIG|
variable.
These default options are applied when no previous configuration target has been
run.

Refer to section Configure_ for a list of variables affecting this target
behavior.

.. _sect-user-variables:

Variables
---------

This section describes all :command:`make` variables that may be given on the
command line to customize the construction logic.

AR
**

Object archiver

:Default: ${CROSS_COMPILE_}ar
:Mutable: yes

Tool used to create static libraries, i.e. built objects archives.

See |ar(1)|.

.. _var-bindir:

BINDIR
******

Executable programs install directory

:Default: ${PREFIX_}/bin
:Mutable: yes

Pathname to directory where to install executable programs. Note that final
install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

.. _var-builddir:

BUILDDIR
********

Build directory

:Default: ${TOPDIR_}/build
:Mutable: yes

Pathname to directory under which intermediate objects are generated. Applies to
all construction phases.

CC
**

C compiler

:Default: ${CROSS_COMPILE_}gcc
:Mutable: yes

Tool used to build C objects.

See |gcc(1)|.

.. _var-cross_compile:

CROSS_COMPILE
*************

Cross compile tool prefix

:Default: empty
:Mutable: yes

Optional prefix prepended to build tools used during construction. The following
variables are affected: AR_, CC_, LD_, STRIP_.

.. _var-cscope:

CSCOPE
******

|Cscope| source tag database generation tool

:Default: ``cscope``
:Mutable: yes

Tool used to generate |Cscope| source code tag database.
See also CTAGS_.

.. _var-ctags:

CTAGS
*****

|Ctags| source tag database generation tool

:Default: ``ctags``
:Mutable: yes

Tool used to generate |Ctags| source code tag database.
See also CSCOPE_.

.. _var-defconfig:

DEFCONFIG
*********

Defaut build configuration file

:Default: empty
:Mutable: yes

Pathname to optional file containing default build configuration settings. This
file may be generated from current configuration as explained into section
configure_.

.. _var-datadir:

DATADIR
*******

Read-only architecture-independent data install directory

:Default: ${PREFIX_}/share
:Mutable: yes

Pathname to directory where to install read-only architecture-independent data
files.

See |gnu_vars_for_install_dirs|.

.. _var-destdir:

DESTDIR
*******

Top-level staged / root install directory

:Default: empty
:Mutable: yes

*DESTDIR* variable is prepended to each installed target file so that the
installed files are not placed directly into their expected location but are
instead copied into an alternate location, *DESTDIR*.
However, installed files maintain their relative directory structure and any
embedded file names will not be modified.


*DESTDIR* is commonly used in package creation and cross compile environment.
See section `Staged install`_ and |gnu_install_destdir| for more informations.

.. _var-docdir:

DOCDIR
******

Documentation install directory

:Default: ${DATADIR_}/doc
:Mutable: yes

Pathname to directory where to install documentation files other than man pages
and info files.

See |gnu_vars_for_install_dirs|.

DOXY
****

|Doxygen| documentation generation tool

:Default: ``doxygen``
:Mutable: yes

Tool used to generate source code documentation.
See |doxygen(1)|.

EBUILDDIR
*********

`Ebuild <ebuild_>`_ directory

:Default: empty
:Mutable: yes

Pathname to directory where ebuild_ logic is located.

ECHOE
*****

Shell escaped string echo'ing tool

:Default: ``/bin/echo -e``
:Mutable: yes

Tool used to print strings to console with shell backslash escapes
interpretation enabled. See |echo(1)|.

GIT
***

|Git|, the stupid content tracker command line tool

:Default: ``git``
:Mutable: yes

Tool used to build source distribution tarballs for |Git| based projects.
See |git(1)|.

INFODIR
*******

|Info files| install directory

:Default: ${DATADIR_}/info
:Mutable: yes

Pathname to directory where to install |Info files|.

See |gnu_vars_for_install_dirs|.

INCLUDEDIR
**********

Header files install directory

:Default: ${PREFIX_}/include
:Mutable: yes

Pathname to directory where to install development header files to be included
by the C ``#include`` preprocessor directive.

See |gnu_vars_for_install_dirs|.

.. _var-install:

INSTALL
*******

Install tool

:Default: ``install``
:Mutable: yes

Tool used to copy filesytem entries and set their attributes.
See |install(1)|.

INSTALL_INFO
************

|Info files| page installer tool

:Default: ``install-info``
:Mutable: yes

Tool used to install |texinfo(5)| documentation system |info(5)| pages generated
using |makeinfo(1)| tool.
See also |install-info(1)|.

KCONF
*****

|KConfig| line-oriented tool

:Default: ``kconfig-conf``
:Mutable: yes

Tool used to configure the build logic thanks to a line-oriented user interface
(questions - answers).

See |KConfig|.

KGCONF
******

|KConfig| |GTK| menu based tool

:Default: ``kconfig-gconf``
:Mutable: yes

Tool used to configure the build logic thanks to a |GTK| menu driven user
interface.

See |KConfig|.

KMCONF
******

|KConfig| |NCurses| menu based tool

:Default: ``kconfig-mconf``
:Mutable: yes

Tool used to configure the build logic thanks to a text menu driven user
interface.

See |KConfig|.

KXCONF
******

|KConfig| |QT| menu based tool

:Default: ``kconfig-qconf``
:Mutable: yes

Tool used to configure the build logic thanks to a |QT| menu driven user
interface.

See |KConfig|.

LATEXMK
*******

|LaTeX| documentation builder tool

:Default: ``latexmk``
:Mutable: yes

Tool used to automate the process of building |LaTeX| documents.
See also |latexmk(1)|.

LD
**

Program linker

:Default: ${CROSS_COMPILE_}gcc
:Mutable: yes

Tool used to link objects.

See |gcc(1)| and |ld(1)|.

LIBDIR
******

Libraries install directory

:Default: ${PREFIX_}/lib
:Mutable: yes

Pathname to directory where to install object files and libraries of object
code.
Note that final install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

LIBEXECDIR
**********

Executable programs install directory

:Default: ${PREFIX_}/libexec
:Mutable: yes

Pathname to directory where to install executable programs to be run by other
programs rather than by users.
Note that final install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

LN
**

Link maker tool

:Default: ``ln -f``
:Mutable: yes

Tool used to make links between filesystem entries.
See |ln(1)|.

LOCALSTATEDIR
*************

Machine specific persistent data files install directory

:Default: ${PREFIX_}/var
:Mutable: yes

Pathname to directory where to install data files which the programs modify
while they run, and that pertain to one specific machine.
Note that final install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

MAKEINFO
********

|Info files| documentation conversion tool

:Default: ``makeinfo``
:Mutable: yes

Tool used to generate |info(5)| pages for the |texinfo(5)| documentation system.
See also |install-info(1)|.

MANDB
*****

`Man pages`_ index maintainer tool

:Default: ``mandb``
:Mutable: yes

|mandb(8)| is the tool used to maintain |man(7)| page index caches.

MANDIR
******

Man pages install directory

:Default: ${DATADIR_}/man
:Mutable: yes

Pathname to top-level directory where to install man pages.

See |gnu_vars_for_install_dirs| and |man-pages(7)|.

.. _var-prefix:

PREFIX
******

Prefix prepended to install variable default values.

:Default: :file:`/usr/local`
:Mutable: yes

A prefix used in constructing the default values of some of the variables listed
in the Variables_ section.
Note that final install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

PKG_CONFIG
**********

pkg-config_ compile and link helper tool

:Default: ``pkg-config``
:Mutable: yes

Helper tool used to retrieve flags when compiling applications and libraries.
See pkg-config_ and |pkg-config(1)|.

PKGCONFIGDIR
************

pkg-config_ metadata files install directory

:Default: ${LIBDIR_}/pkgconfig
:Mutable: yes

Pathname to directory where to install |pkg-config(1)| metadata files.

See |gnu_vars_for_install_dirs|.

PYTHON
******

The |python| interpreter version 3.x

:Default: ``python3``
:Mutable: yes

|python| interpreter required by the |sphinx| documentation system.
See |python3(1)| and SPHINXBUILD_.

RM
**

Filesystem entry removal tool

:Default: ``rm -f``
:Mutable: yes

Tool used to delete filesystem entries.
See |rm(1)|.

RSYNC
*****

|rsync| filesystem synchronization tool

:Default: ``rsync``
:Mutable: yes

Tool used to copy / synchronize filesystem hierarchies.
See |rsync(1)|.

RUNSTATEDIR
***********

Machine specific temporary data files install directory

:Default: ${PREFIX_}/run
:Mutable: yes

Pathname to directory where to install data files which the programs modify
while they run, and that pertain to one specific machine, and which need not
persist longer than the execution of the program.
Note that final install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

SBINDIR
*******

System administration executable programs install directory

:Default: ${PREFIX_}/sbin
:Mutable: yes

Pathname to directory where to install executable programs that are only
generally useful to system administrators. Note that final install location is
also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

SPHINXBUILD
***********

|sphinx| documentation generation tool

:Default: ``sphinx-build``
:Mutable: yes

Tool used to generate documentation from a |reST| file hierarchy.
|sphinx-build(1)| may output documentation to multiple format, i.e.
|Info files|, |LaTeX|, *PDF* and *HTML*.
See also PYTHON_, MAKEINFO_, LATEXMK_ and DOXY_.

STRIP
*****

Object symbols discarding tool.

:Default: ${CROSS_COMPILE_}strip
:Mutable: yes

Tool used to discard symbols from compiled and linked object files.
See |strip(1)|.

SVN
***

|Subversion|, the Subversion version control system command line tool

:Default: ``svn``
:Mutable: yes

Tool used to build source distribution tarballs for |Subversion| based projects.
See |svn(1)|.

SYSCONFDIR
**********

Machine specific read-only configuration install directory

:Default: ${PREFIX_}/etc
:Mutable: yes

Pathname to directory where to install read-only data files that pertain to a
single machine, i.e., files for configuring a host.
Note that final install location is also affected by the DESTDIR_ variable.

See |gnu_vars_for_install_dirs|.

TOPDIR
******

Source tree top-level directory

:Default: not applicable
:Mutable: no

Pathname to source tree top-level directory.

.. _sect-user-troubleshooting:

Troubleshooting
===============

In case an error happens such as the one below:

.. code-block:: console

   $ make help
   Makefile:10: *** '/usr/share/ebuild': no valid Ebuild install found !.  Stop.

This means the project is not able to find the location where ebuild_ is
installed.  This *may* happen when working with a project source tree that has
been retrieved from version control system, i.e., not extracted from a source
distribution tarball.

Give :command:`make` an EBUILDDIR_ variable pointing to the top-level ebuild_
read-only data directory like so:

.. code-block:: console

   $ make help EBUILDDIR=/usr/local/share/ebuild
