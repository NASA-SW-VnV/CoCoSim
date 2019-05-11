Troubleshooting
===============

This document covers some common issues with CoCoSim, and how to solve them.

Contact
-------

hamza.bourbouh@nasa.gov

Installation issues
-------------------

**Installing external Matlab libraries:**

Read function `cocosim2/scripts/install_cocosim_lib.m` to know what are the external libraries are copied to cocosim2 to do it manually in case the function failed for internet connexion or `git` issues.

**Installing external tools (Kind2, Lustrec, etc ...):**

If running the script `cocosim2/scripts/install_cocosim` failed. You can install the tools manually and set their path in `cocosim2/tools/tools_config.m`.

The default paths set by `tools_config` are:

[Kind2](http://kind2-mc.github.io/kind2/)  : `cocosim2/tools/verfiers/osx/bin/kind2`

[Zustre](https://github.com/lememta/zustre) : `cocosim2/tools/verfiers/osx/bin/zustre`

[Lustrec](https://github.com/coco-team/lustrec): `cocosim2/tools/verfiers/osx/bin/lustrec`

change `osx` by `linux` if your machine is linux machine.


