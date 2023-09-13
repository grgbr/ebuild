.. SPDX-License-Identifier: GPL-3.0-only
   
   This file is part of eBuild.
   Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>

.. include:: <isonum.txt>

Welcome to eBuild documentation
###############################

**Copyright** |copy| 2019-2023 Grégor Boirie.

This manual is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This manual is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

A copy of the license is included in the section entitled
:ref:`GNU General Public License <gpl>`.

.. Caption of toctrees are not translated into latex, hence the dirty trick
.. below. See https://github.com/sphinx-doc/sphinx/issues/3169 for more infos.
.. Basically, we ask the latex backend to generate a \part{} section for each
.. toctree caption using the `raw' restructuredtext directive.

.. only:: latex

   .. raw:: latex

      \part{User Guide}

.. toctree::
   :numbered:
   :caption: User Guide

   user


.. only:: latex

   .. raw:: latex

      \part{Install Guide}

.. toctree::
   :numbered:
   :caption: Install Guide

   install


.. only:: latex

   .. raw:: latex

      \part{Programmer Guide}

.. toctree::
   :maxdepth: 2
   :numbered:
   :caption: Programmer Guide

   programmer


.. We use the latex_appendices setting into conf.py to benefit from native latex
.. appendices section numbering scheme. As a consequence, there is no need to
.. generate appendix entries for latex since already requested through the
.. latex_appendices setting.

.. only:: latex

   .. raw:: latex

      \part{Appendix}

.. only:: html

   .. toctree::
      :caption: Appendix

      license
      todo
      genindex
