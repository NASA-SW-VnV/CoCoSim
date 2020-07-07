CoCoSim version 1.2 release notes
===================================

Release date
------------

July 7th, 2020

List of features:
----------------

* New way of abstracting Subsystems. The user can attach a contract to a Subsystem 
and choose if the Subsystem implementation will be generated or to be considered as a 
black box.
If the user choose to abstract the Subsystem, the latter code will not be 
generated, only the contract will be used as an abstraction.

To attach a contract, click right on the Subsystem or block you want to abstract,
then click on ```CoCoSim -> attach contract to the selected block```.

CoCoSim version 1.1 release notes
===================================

Release date
------------

May 29th, 2020

List of features:
----------------

* This release contains many bug fixes to v1.0. 
* Also some improvements on Stateflow compiler. 
Stateflow flow chart algorithm was modified to speedup the verification time. On one example, we reduced verification time of a Stateflow flow chart from hours to seconds.
* Add the option to choose which smt solver (Z3 or Yices2) will be used by Kind2.
* We organized Matlab functions files in packages to avoid any conflicts in function names.

CoCoSim version 1.0 release notes
===================================

Release date
------------

Feb 2020

List of features:
----------------
The following is the list of actions the user can call from CoCoSim menu:
* **Check compatibility** of a model against the CoCoSim compiler from Simulink to Lustre: This will check and report all blocks in the model that are not supported by the compiler. \
The checking compatibility does not guarantee that the model is fully supported but it detects the blocks/options we already know we do not support.
You may have other error messages that a specific block is not supported.
In addition the compatibility is performed for Verification, a model can be supported for verification and not for code generation.

* **Prove properties**: The model should contain requirements to be verified by one of the supported model checkers (currently only KIND2 is integrated). These requirements can be expressed using SLDV verification blocks or CoCoSpec specification blocks (See [CoCoSpec Specification library](https://github.com/coco-team/cocoSim2/blob/master/doc/specificationLibrary.md)). 
* **Design Error Detection**: Currently cocosim only check for specified minimum and maximum signal values specified by the user on blocks outputs using OutMin and OutMax parameters in blocks dialogue box. The check is done using Kind2 model checker. Future work is planned to support the check of integer overflow, out of bound access array and division by zero.
This features requires Kind2 to be installed.
* **Test-case Generation**: Currently cocosim supports:
    * **Random Testing**: cocosim generates in this case random inputs, a range can be specified by the user using OutMin and OutMax parameters in the Inport block.
* **Code Generation**: CoCoSim support the generation of C, Lustre and Rust code from a Simulink model.




Features in progress:
---------------------
* Support [nuXmv](https://nuxmv.fbk.eu/) model checker.
* **Check model against guidelines**: This will run the model against a list of guidelines from [NASA - Orion GN&C: MATLAB and Simulink Standards](https://www.mathworks.com/solutions/aerospace-defense/standards/nasa.html).

* **Test-case Generation**: Currently we are working on:
    * **MC-DC test coverage**: cocosim uses lustret tool to generate MC-DC conditions on the lustre code that will be checked using Kind2. Counterexamples are the test-cases that detects those MC-DC conditions. In the case the condition is not falsified, it means the condition is never activated, therefore a dead logic. 
    * **Mutation based testing**: cocosim uses lustret tool to generate mutations on the lustre code, a mutation can be a change of arithmetic operator, a relational operator or a constant value. Kind2 is used to find traces that detect those mutations.
    