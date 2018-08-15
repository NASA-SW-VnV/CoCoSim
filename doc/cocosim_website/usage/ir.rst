Internal Representation of Simulink/Stateflow
=============================================
The internal representation (IR) allows to export the simplified model
into a hierarchical tree-based structure. We present here the structure
and the syntax of its fields. The structure is specific to the input
model. We handle a restricted subset of Simulink components, cf
Sec. \ `0.0.1 <#sec:simulink_ir>`__, a subset of Stateflow automata, cf
Sec. \ `0.0.2 <#sec:stateflow_ir>`__ and some basic Matlab expressions,
cf Sec. \ `0.0.3 <sec:matlab_ir>`__.

.. _sec:simulink_ir:

Simulink IR
-----------

The function ``cocosim_IR`` produces the IR associated to a given
Simulink model. The function’s signature is as follow:

::

   function [ir_struct, all_blocks, subsyst_blocks, handle_struct_map] =
                  cocosim_IR( simulink_model_path, df_export, output_dir )

This function takes one mandatory parameter – the model – and two
optional ones. The option ``df_export`` is disabled by default. When set
to ``true`` the call produces a json file containing the resulting IR
structure. The third parameter ``output_dir`` specifies the path where
the json file is saved. By default the model path is used.

The function returns the IR (a struct in matlab), the list of all blocks
present in the model, the list of all subsystems or blocks treated as
subsystems in the model, and a map of block’s handles (IDs) associated
with the struct of the block in the IR. This last one simplifies IR
accesses for the ``get_struct`` function.

Here is the description of the structure of the IR:

.. raw:: latex

   \lstset{
       string=[s]{"}{"},
       stringstyle=\color{blue},
       comment=[l]{:},
       commentstyle=\color{black},
   }

::

   IR = {"meta" : META, "model_name" : {SUBS_IR}}
   META = {"date" : date, "file_path" : model_path}
   SUBS_IR = "Content" : {BLOCKS_IR}
   BLOCKS_IR =  "block_formated_name" : {PROPERTIES, SUBS_IR}, BLOCKS_IR
   PROPERTIES = PropertyName : value, PROPERTIES

Since field of struct cannot have spaces or line breaks, the block’s
names are first formated to have correct field names. The original one
is contained in the ``Origin_path`` property in the IR.

The first component of the IR is the meta data. It contains informations
such as date of creation of the IR or model path. The model
representation is rather straightforward, each block is defined as its
set of properties and values. The
Figure \ `[fig:IR_SL_1] <#fig:IR_SL_1>`__ presents a simple Simulink
model computing the absolute value of an input flow and
Figure \ `[fig:IR_SL_2] <#fig:IR_SL_2>`__ its IR.

.. raw:: latex

   \centering

.. figure:: /graphics/simple.*
   :alt: Absolute value subsystem.

   Absolute value subsystem.

[fig:IR_SL_1]

.. raw:: latex

   \centering

.. figure:: /graphics/ir_simple.*
   :alt: Absolute value subsystem intermediate representation.

   Absolute value subsystem intermediate representation.

[fig:IR_SL_2]

.. _sec:stateflow_ir:

Stateflow IR
------------

A stateflow chart is represented as a Program with the following
attributes:

::

   SFCHART = {
   			"name" : chart_name, 
   			"origin_path" : Simulink_path_to_chart, 
   			"states": [STATE*],
   			"junctions":[JUNCTION*],
   			"sffunctions":[SFCHART*],
   			"data":[DATA*]
   }
           
   STATE = {
   			"path" : path,
   			"state_actions" : {
   									"entry_act":entry_act,
   									"during_act":during_act,
   									"exit_act":exit_act,
   			},
   			"outer_trans": [TRANSITION*],
   			"inner_trans": [TRANSITION*],
   			"internal_composition": COMPOSITION
   }

   JUNCTION = {
   			"path" : path,
   			"type" : 'CONNECTIVE' | 'HISTORY',
   			"outer_trans": [TRANSITION*]
   }
           
   TRANSITION = {
   			"id": id,
   			"event": event,
    			"condition" : condition,
   			"condition_act": condition_act,
   			"transition_act": transition_act,
   			"dest": {
   									"type": 'State' | 'Junction',
   									"name": dest_name
   			}
   }
                 
   COMPOSITION = {
   			"type": 'EXCLUSIVE_OR'| 'PARALLEL_AND',
   			"tinit": [TRANSITION*],
   			"substates": [substates_names list]
   }
                 
   DATA = {
   			"name": name,
   			"scope": 'Local'| 'Constant'| 'Parameter'| 'Input'| 'Output' ,
   			"datatype": DataType, /*Type of data as determined by Simulink*/
   			"port": port_number, /*Port index number for this data */
   			"initial_value": initial_value,
   			"array_size": array_size, /*Size of data as determined by Simulink.*/
   }             

-  origin_path: the Simulink path to the Stateflow chart.

-  name: The name of the Stateflow chart.

-  states: List of chart’s states, a state is represented by:

   -  path: the full path to the state.

   -  state_actions: State actions (entry, exit and during actions).

   -  outer_trans: List of outer transition of the state. Each
      transition is represented by:

      -  id: a unique ID of the transition.

      -  event: Sting containing the name of the event.

      -  condition: String containing the condition that triggers the
         transition.

      -  condition_act: String containing the condition actions.

      -  transition_act: String containing the transition actions.

      -  dest: The destination of the transition. Which is a structure
         containing:

         -  type: ’State’ or ’Junction’.

         -  name: The path to destination.

   -  inner_trans: List of inner transition of the state.

   -  internal_composition: Is the composition of the state. It has the
      following attributes:

      -  type: even ’EXCLUSIVE_OR’ or ’Parallel_AND’

      -  tinit: List of default transitions of the state.

      -  substates: List of sub-states names of the current state.

-  junctions: List of junctions. Junction is defined by its path, type
   and the outer transition from this junction.

-  sffunctions: List of Stateflow functions. A Stateflow function is a
   special chart, it contains the same attributes that defines a chart.

-  data: List of all chart data variables. A data variable is defined by
   a name, scope (local, input, parameter or output), a datatype (int8,
   int16 ...) and its initial value when defined.

.. _sec:matlab_ir:
Matlab IR
---------

Matlab code can also be exported in a Json format. The Matlab grammar in
ANTLR4 format and java source code handling this grammar can be found in
``cocosim2/src/IR/matlab_IR/EM``. The user can define a new
transformation from Matlab AST to another language or format. Following
the existing example of transforming Matlab to Json format may help.
Fig. \ `[fig:matlab_ir_ex] <#fig:matlab_ir_ex>`__ shows an example of a
simple Matlab function and its equivalent in Json format.

.. raw:: latex

   \centering

| |Internal representation of a simple Matlab code in Json format.|
| |Internal representation of a simple Matlab code in Json format.|

[fig:matlab_ir_ex]

Note that the subset of Matlab expressions accepted of extremelly
limited and cannot involve sophisticated Matlab functions.

.. |Internal representation of a simple Matlab code in Json format.| image:: matlab_code_ex
.. |Internal representation of a simple Matlab code in Json format.| image:: matlab_ir_ex
