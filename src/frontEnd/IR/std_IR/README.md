# IR

IR build an internal representation of Simulink models using matlab's struct.
Here is a description of the structure of the IR :

IR = {”meta” : META
      ”model_name” : {SUBS_IR}
      }
      
META = {”date” : date
        ”file_path” : model_path
        }
        
SUBS_IR = ”Content” : {BLOCKS_IR}

BLOCKS_IR = ”block_formated_name” : {PROPERTIES}
            BLOCKS_IR
            
BLOCKS_IR = ”block_formated_name” : {PROPERTIES, SUBS_IR}
            BLOCKS_IR
            
BLOCKS_IR =  Λ

PROPERTIES = "PropertyName" : value, PROPERTIES

PROPERTIES = Λ

There is one particular field for each block called "Origin_path". It contains the path to the block
with its original name (with space and/or line breaks).

## Configuration
You can set some configuration for existing (in the doc) parameters you want in your IR in
IR_config.m.
For more information look at the description in IR_config.
*It is possible to pre-process the IR to adapt it at your convenience and add non-existing
parameters or modified values of existing parameters.

## Example
You can call cocosim_IR on the example exemple/Model_example.slx file.
ir_struct = cocosim_IR('exemple/Model_example', true). Add true if you want
to save the struct in a json file (Model_example.json).
