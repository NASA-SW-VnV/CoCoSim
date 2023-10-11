## Requirements-Based Testing (Step by step guide)

Note: This feature has been tested with Kind 2 v2.1.0, Z3 4.12.3 and MATLAB R2022b.

This step by step guide provides instructions on how to generate requirements-based tests using FLIP coverage obligations generated from FRET.

### Requirements
+ FRET v3.0
+ Kind2, Z3

### Steps

1. Launch your target Simulink model in MATLAB and ensure that CoCoSim has been launched.
2. Export Model information for the Simulink model by clicking on `Tools -> CoCoSim -> Export Model Information -> FRET`. Follow the prompts in the MATLAB command line window to select the subsystem that you will be generating tests for.
3. A file, named `<Subsystem>_forFRET.json` will be generated in the current MATLAB directory, where `<Subsystem>` is replaced with the name of the Subsystem that you selected during Step 2.
4. [Follow the steps in the FRET guide for exporting the test obligations from your FRETish specification.](https://github.com/NASA-SW-VnV/fret/blob/master/fret-electron/docs/_media/ExportingForAnalysis/analysis.md) Keep note of the following:
    - The `CoCoSpec` export language must be selected before exporting.
    - For the FRET component that contains the relevant requirements to `<Subsystem>`, you must import `<Subsystem>_forFRET.json` using the Import functionality in FRET (see screenshots and text for optional import in step 4b in the FRET guide).
    - When importing is done, you can export the test obligations using the `Export` button next to the corresponding FRET component (see [Export Test Obligations](https://github.com/NASA-SW-VnV/fret/blob/master/fret-electron/docs/_media/exports/testgenManual.md#export-test-obligations) for reference).

    FRET will generate a compressed file containing the following:
        - One Lustre (`.lus`) file per requirement, containing its test obligations.
        - One JSON (`.json`) file containing the mapping of FRET variables to Simulink signals.
5. In the Simulink model in MATLAB, select `Tools -> CoCoSim -> Import -> Test Obligations`.
6. In the pop-up window, select the Lustre file corresponding to the requirement that you want to test, and the JSON file containing the variable mapping information.
7. Click `Import Requirement`.
8. After a while a CoCoSim contract will be generated in Simulink (Note: it may be the case that the contract is not attached to the intended subsystem. If this is the case, manually connect its inports to the corresponding Simulink signals).
9. Create a new subsystem by selecting the target subsystem and the imported Contract, then right-clicking on the selection and in the context menu select `Create Subsystem from Selection`.
10. Change the name of the new subsystem (optional). Right-click on the subsystem and select the option `Block Parameters (Subsystem)`. In the pop-up window, ensure that the `Treat as atomic unit` option is checked, then click on `Apply`.
11. Finally, right-click on the new subsystem and in the context menu select `CoCoSim -> Generate Requirements-Based Tests`.
12. When the process is complete, a new Simulink model will be created containing only the selected subsystem, and a test driver (Signal Builder block) will be attached to its inports. Open the test driver to navigate through the generated tests and perform other actions (e.g. simulate).
    