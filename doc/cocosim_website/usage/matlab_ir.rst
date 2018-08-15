.. _sec:matlab_ir:

Matlab IR
=========

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
