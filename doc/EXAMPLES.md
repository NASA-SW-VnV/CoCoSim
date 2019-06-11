## Examples

### Start CoCoSim
For every new Matlab session:
+ Launch Matlab(c)
+ Navigate to `cocosim2/`
+ Run in Matlab command window ```start_cocosim```

### Check Compatibility example:

1. To test an example for compatibility: `open examples/contract/bacteriaPopulationStateflow.slx`
2. Set your default Simulink to Lustre compiler to NASA compiler in `Tools -> CoCoSim -> Preferences -> Simulink To Lustre compiler -> NASA compiler `. The second compiler does not support a compatibility check.
3. Under the `Tools -> CoCoSim` menu choose `Check Compatibility`.

You will get an HTML report with Unsupported blocks. In this example, the chart block is not supported for the reason "Event "dummyEvent" in chart bacteriaPopulationStateflow_PP/bacteriaPopulation/bacteriaPopulation with "Function call" Trigger is not supported.".

To fix it, click right on the chart block, then click on `explore` and remove the event "dummyEvent" (by clicking right and do Cut or click on delete on tools bar).

### Check Model against guidelines:

1. To test an example for guidelines: `open examples/guidelines/guideLines1.slx`
2. Under the `Tools -> CoCoSim` menu choose `Check model against guidelines`.

An Html report should be generated containing guidelines devided in three categories: Mandatory, Strongly Recommended, Recommended. Click on each one of them to get more details.

### Requirements verification example:

1. To test an example with properties: `open examples/contract/absolute.slx`
2. Set your default model checker in `Tools -> CoCoSim -> Preferences -> Verification Backend `
3. Under the `Tools -> CoCoSim` menu choose `Prove properties`.


### Test-case generation example:

1. To test an example with properties: `open examples/test_generation/mcdc_test.slx`
2. Under the `Tools -> CoCoSim` menu choose `Test-case generation using...`.