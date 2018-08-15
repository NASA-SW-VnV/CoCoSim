Install dependencies
====================

Dependencies install can be eased with a dedicated script. It requires
access to internet since it downloads sources and perform git accesses.
It mainly performs two steps: first, it downloads, compiles and installs
in a local folder the external tools required by ; and then it downloads
from a public repositories the standard library for each phase:
front-end, middle-end, back-end.

::

   $cd "PATH\_TO\_CoCoSim/scripts"
   $./install\_cocosim 

Basic dependencies.
-------------------

``install_cocosim`` script assumes that the operating system provides:
``bash``, ``basename``, ``dirname``, ``mkdir``, ``touch``, ``sed``,
``date``, ``cat``, ``rm``, ``mv``, ``cp``, ``ln``, ``find``, ``tee``,
``patch``, ``tar``, ``gzip``, ``gunzip``, ``xz``, ``make``, ``install``,
``git`` as well as the following tools ``autoconf``, ``automake``,
``aclocal``, ``pkg-config``.

Tools dependencies.
-------------------

The script detects the missing tools and performs their installation. By
default it installs the following ones: Zustre, Spacer, Lustrec, Kind2.
They are installed in a local path, ``tools/verifiers/osx`` if you are
Mac user or ``tools/verifiers/linux`` for Linux platforms.

For example, on a Mac, we obtain the following binaries:

-  ZUSTRE : ‘cocoSim/tools/verfiers/osx/zustre/bin/zustre‘

-  LUSTREC: ‘cocoSim/tools/verfiers/osx/lustrec/bin/lustrec‘

-  KIND2 : ‘cocoSim/tools/verfiers/osx/kind2/bin/kind2‘

One can rely on an existing version of those tools. This can be
parametrized in ``tools/tools_config.m``, providing path to tools. One
can also copy the binary in the ``tools/verifiers`` folders.

Libraries.
----------

distribution is provided with the core algorithm but each phase is
parametrized and extensible through libraries. The standard library is
available on a public github repository and involves contributions from
CMU, University of Iowa, Onera and IRIT. The install script copies these
libraries such as the pre-processing standard ``src/pp/std_pp`` and the
internal representation ``src/IR/std_IR``.

The dependencies can be summarized as follows:

-  MATLAB(c) version **R2015a** or newer

-  If you need for verification, at least one of the following solvers
   should be installed:

   -  **Kind2** http://kind2-mc.github.io/kind2/

   -  **Zustre** https://github.com/lememta/zustre

   -  **JKind** https://github.com/agacek/jkind – for Windows OS users,
      since it is developped in Java.

   -  We recommend **Kind2** and **Zustre**. **Kind2** shows more
      capabilities in the number of properties solved.

-  If you need to analyze the generated C code from the Simulink model,
   at least on of the following solvers should be installed:

   -  **IKOS** https://ti.arc.nasa.gov/opensource/ikos/

      -  In addition to IKOS, you need to install whole **LLVM**

         -  https://github.com/travitch/whole-program-llvm

         -  Or, using pip: “pip install wllvm”

   -  **SeaHorn** http://seahorn.github.io/

-  Python2.7

Configuration.
--------------

Edit ``cocosim_config.m`` and follow the commented instructions.
