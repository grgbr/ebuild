.. SPDX-License-Identifier: GFDL-1.3-only
   
   This file is part of eBuild.
   Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>

.. include:: <isonum.txt>

Welcome to eBuild documentation
###############################

**Copyright** |copy| 2019-2023 Grégor Boirie.

Permission is granted to copy, distribute and/or modify this document under the
terms of the GNU Free Documentation License, Version 1.3 or any later version
published by the Free Software Foundation; with no Invariant Sections, no
Front-Cover Texts, and no Back-Cover Texts.

A copy of the license is included in the section entitled
:ref:`GNU Free Documentation License <gfdl>`.

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
