CoCoSim version 1.0.0 release notes
===================================

Release date
------------

May 2019

List of features:
----------------
The following is the list of actions the user can call from CoCoSim menu:
* **Check compatibility** of a model with the CoCoSim compiler from Simulink to Lustre: This will check and report all blocks in the model that are not supported by the compiler. 
* **Check model against guidelines**: This will run the model against a list of guidelines from [NASA - Orion GN&C: MATLAB and Simulink Standards](https://www.mathworks.com/solutions/aerospace-defense/standards/nasa.html).
* **Prove properties**: The model should contain requirements to be verified by one of the supported model checkers (currently only KIND2). These requirements can be expressed using SLDV verification blocks or CoCoSpec specification blocks (See [CoCoSpec Specification library](doc/specificationLibrary.md)). 
* **Design Error Detection**: Currently cocosim only check for specified minimum and maximum signal values specified by the user on blocks outputs using OutMin and OutMax parameters in blocks dialogue box. The check is done using Kind2 model checker. Future work is planned to support the check for integer overflow, out of bound access array and division by zero.





Features in progress:
---------------------

* **Test-case Generation**: Currently cocosim supports:
    * **MC-DC test coverage**: cocosim uses lustret tool to generate MC-DC conditions on the lustre code that will be checked using Kind2. Counterexamples are the test-cases that detects those MC-DC conditions. In the case the condition is not falsified, it means the condition is never activated, therefore a dead logic. 
    * **Mutation based testing**: cocosim uses lustret tool to generate mutations on the lustre code, a mutation can be a change of arithmetic operator, a relational operator or a constant value. Kind2 is used to find traces that detect those mutations.
    * **Random Testing**: cocosim generates in this case random inputs, a range can be specified by the user using OutMin and OutMax parameters in the Inport block.