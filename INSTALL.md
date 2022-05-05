

### **Dependencies**

* MATLAB(c) and Simulink version **R2017** or newer (CoCoSim has been well tested in R2017b version)

* [Lustrec](https://github.com/coco-team/lustrec) tool is a modular compiler of Lustre code into C and Horn Clauses. CoCoSim uses lustrec in many features: Test case generation, requirements importation... 

* [Kind2](http://kind2-mc.github.io/kind2/) is a multi-engine, parallel, SMT-based automatic model checker for safety properties of Lustre programs.

<!-- * Formal verification backends: In order to analyse the model, at least one of the following model-checkers should be installed. Currently we support Kind2.
    * [Kind2](http://kind2-mc.github.io/kind2/) (Supported and highly recommended)
    * [Zustre](https://github.com/lememta/zustre) (Support in progress)
    * [JKind](https://github.com/agacek/jkind) (Support in progress) -->



CoCoSim uses the following external libraries:

* CoCoSim standard libraries from https://github.com/coco-team/cocoSim2
* Simulink/Matlab selected toolboxes from https://github.com/hbourbouh/cocosim-external-libs


### **Installation**

Note: The CoCoSim installation script requires `opam`, version `2.1.0` or greater.

#### Using latest stable version 

We recommend this option. You can download the latest stable version of CoCoSim source code from [here](https://github.com/NASA-SW-VnV/CoCoSim/releases).

CoCoSim is a Matlab Toolbox, in the zip we include the external libraries and binaries for Lustrec and Kind2.

You still need to run the install script to make sure binaries are working on your machine. If not they will be installed from scratch.

In your terminal, go first to `scripts` folder in `cocosim` and run the `install_cocosim` script.
```
>cd CoCoSim/scripts
>./install_cocosim 
```

The script may require some dependencies, please install them and run the script again.


#### Using Github source code

1. Clone this cocosim repository in your local machine (develop branch).

2. Download External Matlab Libraries:
   
    * Open your Matlab and navigate to `cocosim/scripts` run `install_cocosim_lib(true)` from the Matlab Command window. \
    Function `cocosim2/scripts/install_cocosim_lib.m` is responsible of copying all required external libraries to the right destination in our repository.
    It needs `git` to clones external repositories from github and copy some of their code on the
    right place on CoCoSim.
    In case the function failed for internet connection or `git` issues, Read function `cocosim2/scripts/install_cocosim_lib.m` to know what are the external libraries are copied to cocosim2 to do it manually.

     * Navigate back to `cocosim` then run `start_cocosim` from the Matlab Command window.

3. In your terminal, go first to `scripts` folder in `cocosim` and run the `install_cocosim` script.
    ```
    >cd scripts
    >./install_cocosim 
    ```

install_cocosim script assumes the operating system provides:
    bash, basename, dirname, mkdir, touch, sed, date,
    cat, rm, mv, cp, ln, find, tee, patch,tar, gzip, 
    gunzip, xz, make, git

Also the following dependencies:
autoconf, automake, aclocal, pkg-config.

The script detects the missing dependencies that should be installed by 
the user.

If the above script failed to install the tools. You may install them in the following paths. If you have linux machin, change `osx` by `linux`.

KIND2 binary: `CoCoSim/tools/verfiers/osx/bin/kind2`

Z3 binary: `CoCoSim/tools/verfiers/osx/bin/z3`

<!-- JKIND binary: `CoCoSim/tools/verfiers/jkind/jkind` -->

<!-- JLUSTRE2KIND binray: `CoCoSim/tools/verfiers/jkind/jlustre2kind` -->

<!-- ZUSTRE binary: `CoCoSim/tools/verfiers/osx/bin/zustre` -->

LUSTREC binary: `CoCoSim/tools/verfiers/osx/bin/lustrec`

LUSTRET binary: `CoCoSim/tools/verfiers/osx/bin/lustret`

LUCTREC_INCLUDE_DIR: `CoCoSim/tools/verfiers/osx/include/lustrec`


If you want to customize these paths go to `cocosim/tools/tools_config.m` and change the values of variables KIND2, Z3, <!--JKIND, JLUSTRE2KIND, ZUSTRE, --> LUSTREC, LUSTRET, LUCTREC_INCLUDE_DIR to your preferences.


**Quick Start**
-------------------
Explanation for each CoCoSim features can be found [here](doc/EXAMPLES.md)

**Notes**
-------------------
**Ubuntu 20.04 + MATLAB R2020 users :** If running the verification example doesn't work (z3 not found error), please make sure that your environment has libstdc installed, then call MATLAB with the following flag (replace "version" suffix in the LD_PRELOAD path with your installed version, tested on versions 6.0.28 and 6.0.29 so far):
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.version /path/to/matlab/binary

