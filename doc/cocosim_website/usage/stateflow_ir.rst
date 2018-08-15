.. _sec:stateflow_ir:

Stateflow IR
============

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
