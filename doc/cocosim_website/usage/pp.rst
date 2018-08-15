Preprocessing blocks
====================
The idea behind the pre-processing (as described in
Fig. \ `[fig:pp_blocks] <#fig:pp_blocks>`__) is to transform a Simulink
model with complex blocks to one that uses basic Simulink blocks.

.. raw:: latex

   \centering

.. figure:: /graphics/pp_blocks.*
   :alt: Some of pre-processing libraries.

   Some of pre-processing libraries.

[fig:pp_blocks]

For example Fig `[fig:pp_ex1] <#fig:pp_ex1>`__ illustrates the
pre-processing of a Saturation block: such a block can, without loss of
precision, be transformed into a combination of min and max operators.
Fig. \ `[fig:pp_ex23] <#fig:pp_ex23>`__ proposes the expression of a
``TransferFcn`` block as a sub-system describing its linear system
realization. This process can be applied on a discrete transfer function
without loss of precision, while its application to continuous transfer
function can be appropriate or not depending on the context.

.. raw:: latex

   \centering

.. figure:: /graphics/pp_ex1.*
   :alt: Example of simplifying the Saturation block.

   Example of simplifying the Saturation block.

[fig:pp_ex1]

.. raw:: latex

   \centering

| 

[fig:pp_ex23]

We present here the Matlab function performing the pre-processing. Then
we present how the pre-processing can be tuned and extended.

Matlab Function
---------------

pre-processing which converts a Simulink model into a -friendly one is
automatically called when using the complete framework. It could also be
called independently on a given model to simplify it. The function
``cocosim_pp`` can be used as follows:

-  ``cocosim_pp('path_to_model.slx')``: the model is processed and its
   processed copy is produced in the file ``path_to_model_PP.slx``. Note
   that if the given file is already a pre-processed file ``*_PP.slx``
   the modification is performed in place.

-  ``cocosim_pp('path_to_model.slx','constant_filename.m')``: If the
   Simulink model needs the definition of constants to be fully defined,
   they can be provided through a ``.m`` file.

-  ``cocosim_pp('path_to_model.slx','model_constants.m','verif')`` with
   all its paremeters or ``cocosim_pp('path_to_model.slx',,'verif')``
   without the constant file part: a third option parameter can be used
   to validate the pre-processing. It generates a Simulink model
   containing the original model and the pre-processed model for
   validation.

   The function ``cocosim_pp`` will then generate, in addition to the
   pre-processed model, a new model containing both models as well as
   means of simulating both models outputs for the same inputs. The
   feature is used for non regression tests and can be used to validate
   a specific pre-processing.

In all cases, ``cocosim_pp`` needs to compile the model during its
execution. It relies on the type inference of the simulation engine to
discover the type of variables. Indeed most users of Simulink do not
specify types but rather rely on the :math:`-1` value denoting
inheritance, ie. type inference. If the pre-processing lacks the values
of certain parameters, it may fail.

Matlab r2014b or newer is required because of its python capabilities.
Calling ``cocosim_pp`` in an older version of Matlab is feasible but any
call of the Python parser script will fail, while the computation is
completed, errors being reported to the user. Some cases are postponed
and will be handled by translator, such as constants, gain block,
discrete integrator and Fcn blocks.

.. _sec:pp_config:

Pre-Processing configuration
----------------------------

pre-proccessing performs a sequence of model-to-model transformation,
following a given order. The structure of architecture is highly generic
and the pre-processing can be a combination of multiple preprocessing
librariries, with a specific order.

The default libraries are coming from two sources: one defined by CMU
and one developped within NASA. Both libraries are complimentary and
perform different pre-processing.

Configure pre-processing order programmatically
"""""""""""""""""""""""""""""""""""""""""""""""

The function call order is specified in ``main/pp_order.m``. The
pre-processing tree is presented in
Fig. \ `[fig:pp_tree] <#fig:pp_tree>`__.

.. raw:: latex

   \centering

.. raw:: latex

   \subfloat[Pre-Processing tree]{
         \includegraphics[scale=0.5]{pp_tree}
         \label{fig:pp_tree}
   %      \caption{Pre-Processing tree}
       }

.. raw:: latex

   \subfloat[Pre-Processing configuration file]{
         \includegraphics[scale=0.45]{pp_order}
         \label{fig:pp_order}
   %      \caption{Pre-Processing configuration file.}
       }

[fig:pp_tree_order]

The ``std_pp`` and ``pp2`` folders are two libraries that offer some
pre-processing functions. ``std_pp`` refers to the standard library from
CMU while ``pp2`` is from NASA. The file ``main/pp_order.m`` (Fig.
`[fig:pp_order] <#fig:pp_order>`__) defines which functions have to be
executed and their order. ``pp_handled_blocks`` and
``pp_unhandled_blocks`` are variables defining accepted and rejected
blocks. Functions are defined thanks to their relative path to the
pre-processing folder. The user can give an absolute path to other
functions not exist in source code.

The map ``pp_order_map`` defines a priority for each set of functions.
Priority :math:`-1` is associated to ignored functions. Priority
:math:`0` is the highest priority and functions are run by the ascending
order of priority. Regular expressions can be used. For example, one can
give priority :math:`3` to all functions in folder ‘pp2/blocks’ using:

::

    pp_order_map(3) = {'pp2/blocks/*.m'};

GUI-order configuration
"""""""""""""""""""""""

An configuration GUI (Fig.
`[fig:pp_user_config] <#fig:pp_user_config>`__) helps the user to define
the order of functions and adding new functions. It can be called using
the function ``pp_user_config`` in Matlab command line.

.. raw:: latex

   \centering

.. figure:: /graphics/pp_user_config.*
   :alt: Pre-Processing user configuration interface

   Pre-Processing user configuration interface

[fig:pp_user_config]

Extending Pre-Processing Libraries
----------------------------------

The user can define more pre-processing libraries. The simplest way is
to add the new functions in one of the folders ``pp/pp2`` or
``pp/str_pp``. Any function added to the previous folders will be
executed unless given priority -1. The user can also define his personal
folder. In that case, the user should follow the configuration steps in
section `0.0.2 <#sec:pp_config>`__.

Existing libraries.
"""""""""""""""""""

Please refer to section `[sec:pp_annex] <#sec:pp_annex>`__ for more
details.
