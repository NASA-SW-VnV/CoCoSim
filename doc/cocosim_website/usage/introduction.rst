Overview of the platform
========================
CoCoSim struture
----------------

CoCoSim is strutured as a compiler, sequencing a serie of translation steps
leading, eventually to either the production of source code, or to the
call to a verification tool. By design, each phase is highly
parametrizable through an API and could then be used for different
purposes depending on the customization.

The Figure \ `[fig:cocosim_arch] <#fig:cocosim_arch>`__ outlines the
different steps.

.. raw:: latex

   \centering

.. figure:: /graphics/cocosim2_framework.*
   :alt: CoCoSim framework

   CoCoSim framework

[fig:cocosim_arch]

Front-End.
----------

CoCoSim is a toolbox that can be called directly from the Matlab Simulink
environment (similar to `Simulink Design
Verifier <https://www.mathworks.com/products/sldesignverifier.html>`__).
CoCoSim can be used either for code generation (e.g. C/Rust and/or Lustre), for
test-case generation or for property verification (More back-ends are in
progress). The front-end performs a bunch of pre-processing (i.e.
lowering of different Simulink blocks into basic blocks, see section :doc:`pp`)
and optimizations. The second step of the front-end is generating an intermediate representation of the
Simulink model. This intermediate representation can be exported as a
Json file.

Middle-End: Compiler from Simulink to formal language.
------------------------------------------------------

This step translates modularly the pre-processed Simulink model and
generates a formal language. The main target is currently Lustre models
while other outputs from the internal representation could be produced.
Moreover, it performs book-keeping of the different Simulink/Stateflow
constructs (e.g. signal name, block type etc ..). This allows to trace
Simulink/Stateflow constructs in the resulting Lustre programs.

Back-End: CoCoSim features.
---------------------------

CoCoSim back-ends provide most of CoCoSim features. From specifying properties
  graphically to verifying these properties or generating test-cases.
  Some features require the execution of the complete chain, from
  pre-processing to Lustre generation, ie. verification or test-case
  generation tools. Some others remain at Simulink level, ie. tools
  supporting the definition of requirements.
| The current features of CoCosim can be found in
  Section :doc:`backendFeatures`.

