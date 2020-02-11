Simulink unit tests generation
==============================

In this folder, every Simulink block will be represented by a class that 
automatically generates Simulink unit tests. This automated generation helps 
covering most of all possible combinations of a block parameters.


How to run
----------

Each class is implementing "generateTests" method that takes an object of 
that class and the output of that directory:
For example:
To generate unit test for Abs block, execute the following:

> b = Abs_Test();
> b.generateTests('PATH/TO/WHERE/YOU/WANT/TESTS/TO/BE/GENERATED')

To generate unit tests for all blocks in a given directory:

> outputDir = "Path/to/where/tests/should/be/generated"
> deleteIfExists = false; % If set to true, tests will be overwritten. Otherwise, the existing tests will be skipped.
> Block_Test.generateAllTests(outputDir, deleteIfExists)

Tests will be generated in seperate folders in the "$outputDir". Every block will 
have its own folder inside the "$outputDir"