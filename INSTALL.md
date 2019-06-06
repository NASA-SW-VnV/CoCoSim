
### Dependencies

* MATLAB(c) and Simulink version **R2017** or newer (CoCoSim has been well tested in R2017b version)
* External Matlab libraries :
    * CoCoSim standard libraries from https://github.com/coco-team/cocoSim2
    * Simulink/Matlab selected toolboxes from https://github.com/hbourbouh/cocosim-external-libs
* [Lustrec](https://github.com/coco-team/lustrec) tool is a modular compiler of Lustre code into C and Horn Clauses. CoCoSim uses lustrec in many features: Test case generation, requirements importation... 
* Formal verification backends: In order to analyse the model, at least one of the following model-checkers should be installed. Currently we support Kind2.
    * [Kind2](http://kind2-mc.github.io/kind2/) (Supported and highly recommended)
    * [Zustre](https://github.com/lememta/zustre) (Support in progress)
    * [JKind](https://github.com/agacek/jkind) (Support in progress)

### Installation
There are two steps to install the above dependencies, both are automated in two scripts.
Both steps needs internet connection and git to be installed to clone remote repositories.
* 1st step: Open your Matlab, navigate to cocosim then run ``` start_cocosim```.

This will update cocosim repository and copy the external Matlab libraries.

* 2nd step: run from your teminal the installation script: The script will install Kind2, Zustre, Lustrec and Z3.
```
>cd $PATH_TO_CoCoSim/scripts
>./install_cocosim 
```
where $PATH_TO_CoCoSim should be replaced by your path to CoCosim folder.

install_cocosim script assumes the operating system provides:
    bash, basename, dirname, mkdir, touch, sed, date,
    cat, rm, mv, cp, ln, find, tee, patch,tar, gzip, 
    gunzip, xz, make, git

Also the following dependencies:
autoconf, automake, aclocal, pkg-config.

The script detects the missing dependencies that should be installed by 
the user.

this commande will install Zustre, Spacer, Lustrec, Kind2 
under `tools/verifiers/osx` if you are Mac user or `tools/verifiers/linux` in the case of a linux machine.

For example, if the above script failed to install the tools. You may install them in the following paths. If you have linux machin, change "osx" by "linux".

KIND2 binary: `cocoSim/tools/verfiers/osx/bin/kind2`

Z3 binary: `cocoSim/tools/verfiers/osx/bin/z3`

JKIND binary: `cocoSim/tools/verfiers/jkind/jkind`

JLUSTRE2KIND binray: `cocoSim/tools/verfiers/jkind/jlustre2kind`

ZUSTRE binary: `cocoSim/tools/verfiers/osx/bin/zustre`

LUSTREC binary: `cocoSim/tools/verfiers/osx/bin/lustrec`

LUSTRET binary: `cocoSim/tools/verfiers/osx/bin/lustret`

LUCTREC_INCLUDE_DIR: `cocoSim/tools/verfiers/osx/include/lustrec`


If you want to customize these paths go to `cocosim/tools/tools_config.m` and change the values of variables KIND2, Z3, JKIND, JLUSTRE2KIND, ZUSTRE, LUSTREC, LUSTRET, LUCTREC_INCLUDE_DIR to your preferences.