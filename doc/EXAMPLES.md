## Quick Start

### Start CoCoSim
For every new Matlab session:
+ Launch Matlab(c)
+ Navigate to `CoCoSim/`
+ Run in Matlab command window ```start_cocosim```

You can add the previous steps in your ```startup.m``` script in ```MATLAB``` directory. If the script does not exist you can create a new one. 
At startup, MATLAB automatically executes, if it exists on the MATLAB search path, startup function. Read more about it hear [User-defined startup script for MATLAB](https://www.mathworks.com/help/matlab/ref/startup.html)

### **Check Compatibility example**:

<!-- 1. To test an example for compatibility: `open examples/contract/bacteriaPopulationStateflow.slx` -->
1. Open your Simulink model
2. Set your default Simulink to Lustre compiler to NASA compiler in `Tools -> CoCoSim -> Preferences -> Simulink To Lustre compiler -> NASA compiler `. The second compiler does not support a compatibility check.
3. Under the `Tools -> CoCoSim` menu choose `Check Compatibility`.

The checking compatibility does not guarantee that the model is fully supported but it detects the blocks/options we already know we do not support.
You may have other error messages that a specific block is not supported.
In addition the compatibility is performed for Verification, a model can be supported for verification and not for code generation.

<!-- You will get an HTML report with Unsupported blocks. In this example, the chart block is not supported for the reason "Event "dummyEvent" in chart bacteriaPopulationStateflow_PP/bacteriaPopulation/bacteriaPopulation with "Function call" Trigger is not supported.".

To fix it, click right on the chart block, then click on `explore` and remove the event "dummyEvent" (by clicking right and do Cut or click on delete on tools bar). -->



<!-- ### Check Model against guidelines:

1. To test an example for guidelines: `open examples/guidelines/guideLines1.slx`
2. Under the `Tools -> CoCoSim` menu choose `Check model against guidelines`.

An Html report should be generated containing guidelines devided in three categories: Mandatory, Strongly Recommended, Recommended. Click on each one of them to get more details. -->

### **Requirements formal verification example**:

1. To test an example with properties: `open examples/demo/ABC.slx`. The example is described in the following figure.
![](images/ABC.png)
2. Set your default model checker in `Tools -> CoCoSim -> Preferences -> Verification Backend`. Currently, only [Kind2](https://github.com/kind2-mc/kind2) is supported.
3. Enable or Disable Compositional setting for Kind2 in `Tools -> CoCoSim -> Preferences -> Kind2 Preferences -> Compositional Analysis`. Read more about Compositional Analysis in the 
[user manual](cocosim_user_manual.pdf).
4. You can set other preferences such as `Verification Timeout`, `CoCoSim Verbosity`, `Compiler Preferences` ... in `Tools -> CoCoSim -> Preferences`.
5. Under the `Tools -> CoCoSim` menu choose `Prove properties`.



<!-- ### Test-case generation example:

1. To test an example with properties: `open examples/test_generation/mcdc_test.slx`
2. Under the `Tools -> CoCoSim` menu choose `Test-case generation using...`. -->