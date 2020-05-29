Troubleshooting
===============

This document covers some common issues with CoCoSim, and how to solve them.

Contact
-------

Please contact us at cocosim@lists.nasa.gov with any issue. Or use Github issues reporting system.

Installation issues
-------------------

**Installing external Matlab libraries:**

CoCoSim uses some libraries from [cocosim2](https://github.com/coco-team/cocoSim2) and [AutoLayout](https://github.com/hbourbouh/cocosim-external-libs).

Function `cocosim2/scripts/install_cocosim_lib.m` is responsible of copying all required external libraries to the right destination in our repository.
It needs `git` to clones external repositories from github and copy some of their code on the
right place on CoCoSim.
Read function `cocosim2/scripts/install_cocosim_lib.m` to know what are the external libraries are copied to cocosim2 to do it manually in case the function failed for internet connection or `git` issues.

To call the function in Matlab Command Window:
```
install_cocosim_lib(true)
```

## Install script issues
### Missing libraries:

**Error: gmb.h Cannot be found**

you need to install libgmp3-dev 
```
apt-get install  libgmp3-dev
```



### Installing external tools (Kind2, Lustrec, etc ...):

If running the script `cocosim2/scripts/install_cocosim` failed. You can install the tools manually and set their path in `cocosim2/tools/tools_config.m`.

The default paths set by `tools_config` are:

[Kind2](http://kind2-mc.github.io/kind2/)  : `cocosim2/tools/verfiers/osx/bin/kind2`

<!-- [Zustre](https://github.com/lememta/zustre) : `cocosim2/tools/verfiers/osx/bin/zustre` -->

[Lustrec](https://github.com/coco-team/lustrec): `cocosim2/tools/verfiers/osx/bin/lustrec`

change `osx` by `linux` if your machine is a linux machine.

See [INSTALL.md](../INSTALL.md) 


