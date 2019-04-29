
### Dependencies

* MATLAB(c) and Simulink version **R2016** or newer
* External Matlab libraries :
    * CoCoSim standard libraries from https://github.com/coco-team/cocoSim2
    * Simulink/Matlab selected toolboxes from https://github.com/hbourbouh/cocosim-external-libs
* [Lustrec](https://github.com/coco-team/lustrec) tool is a modular compiler of Lustre code into C and Horn Clauses. CoCoSim uses lustrec in many features: Test case generation, requirement importation... 
* Formal verification backends: In order to analyse the model, at least one of the following model-checkers should be installed. Currently we support Kind2.
    * [Kind2](http://kind2-mc.github.io/kind2/) (Supported and highly recommended)
    * [Zustre](https://github.com/lememta/zustre) (Support in progress)
    * [JKind](https://github.com/agacek/jkind) (Support in progress)

### Installation
There are two steps to install the above dependencies, both are automated in two scripts.
Both steps needs internet connection and git to be installed to clone remote repositories.
* 1st step: Open your Matlab, go to where cocosim is cloned. Add cocosim2 folder to path (only cocosim2 without its sub-folders). Run
```
start_cocosim
```
This will update cocosim repository and copy the external Matlab libraries.

* 2nd step: run from your teminal the installation script: The script will install Kind2, Zustre, Lustrec and Z3.
```
$cd "PATH_TO_CoCoSim/scripts"
$./install_cocosim 
```
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

For example, if the above script failed to install the tools. You may install them and put the 
in the following paths. If you have linux machin, change "osx" by "linux".

KIND2  : `cocoSim/tools/verfiers/osx/bin/kind2`

ZUSTRE : `cocoSim/tools/verfiers/osx/bin/zustre`

LUSTREC: `cocoSim/tools/verfiers/osx/bin/lustrec`



If you want to use your version of the previous tools, go to `tools/tools_config.m`
and configure the tools paths. Or you can copy them under `tools/verifiers` 
as described above.

The command will also copy the standard libraries from Github to cocosim folder.
Which are the pre-processing standard `src/pp/std_pp` and the internal representation
 `src/IR/std_IR`.
...



