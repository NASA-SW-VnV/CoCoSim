Use cases
=========

Use case : TCM
--------------

| The TCM refers to Transport Class Model, is a commercial aircraft
  control system, scaled up from the Generic Transport Model (GTM). It
  is a Simulink model of a twin-engine aircraft simulation. The TCM is
  not intended as a high-fidelity simulation of any particular transport
  aircraft. Rather, it is meant to be representative of the types of
  non-linear behaviors of this class of aircraft. The TCM includes
  models for the avionics (with transport delay), actuators, engines,
  landing gear, nonlinear aerodynamics, sensors (including noise),
  aircraft parameters, equations of motion, and gravity. It is primarily
  implemented in Simulink, consisting of approximately 5700 Simulink
  blocks. Our work studies the guidance and controls models and their
  properties.
| CoCoSim was used to verify 11 high-level safety requirements of the
  TCM. 5 requirements were proved SAFE, 5 were UNSAFE with a
  counterexample and 1 requirement was unkown as the model-checker
  couldn’t find an answer.

The Simulink model can be found in
https://github.com/coco-team/benchmarks/tree/master/Simulink/tcm.


