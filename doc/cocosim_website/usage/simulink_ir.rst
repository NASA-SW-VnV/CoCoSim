.. _sec:simulink_ir:

Simulink IR
===========

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
