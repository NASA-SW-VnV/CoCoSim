Formalize requirements as Simulink components
=============================================
.. role:: raw-latex(raw)
   :format: latex
..

A major step when considering formal verification of models or software
is the need to specify requirements in a formal fashion. Formalization
of requirements means expressing specification, which is usually defined
in large documents using natural languages, as computer-processable
elements. Depending on the context, on the kind of specifications or on
objects of studies, these elements can be logical predicates, physical
measures associated to resources, or even other programs.

A strong benefit of synchronous languages such as Simulink, Scade or
Lustre is the possibility to rely on regular model constructs to specify
these requirements as model components. These are called synchronous
observers.

In this first part of the document, we provide some insights regarding
their definition and their use to support verification and validation
activities.

Synchronous language and Synchronous observers
----------------------------------------------

A glance at synchronous dataflow languages
""""""""""""""""""""""""""""""""""""""""""

Let us first outline the specificities of synchronous languages and draw
some parallel between constructs.

Synchronous languages aim at specifying the behavior of synchronous
reactive systems. This model of computation describes programs that
intend to be run forever, repeating the same computation regularly, at
fixed time steps. Usually the time step length is not an element of the
program itself but more like a meta information required for further
developments such as the scheduling of multiple processes. Synchronous
models assume that the processing time of functions is immediate and
communication is assumed
instantaneous :cite:`DBLP:journals/pieee/BenvenisteCEHGS03`.
These unreasonable hypotheses allow to separate the concerns: on the one
hand, a functional description of the computation – the model –, and, on
the other hand, physical constraints: the evaluation of the function
body has to meet the deadlines. For example, if the program is expected
to be executed 100 times a second, ie. at 100Hz, then the evaluation of
the function should be performed is less than 10 ms. This constraint is
the subject of dedicated analyses such as the computation of worst case
execution time or the computation of bounds over network delays. It can
also impact the hardware development, providing requirements in terms of
computational power.

That said, the model itself can focus on functional behavior and the
computations performed at each time step, regardless of these time step
lengths.

Among the varieties of synchronous languages, let us focus briefly on
three of them. First Matlab Simulink, produced by TheMathWorks. It is a
*de facto* standard in the industry and supported by strong Matlab
toolboxes, providing a large set of advanced mathematical functions. One
of the strong point of Simulink is the capability, in the model, to
denote both continuous and discrete components. While continuous
components will have, eventually, to be discretized before being
executed on the final embedded platform, they are essential ingredients
of the development process of controllers. Indeed, the theory of control
largely rely on continuous models to first describe the plant semantics
and then design a feedback controller satisfying desirable properties of
stability, robustness and performances. Simulink is also fitted with
strong simulation means enabling the computation of traces of models
combining discrete components and continuous ones specified with ODEs
(Ordinary Differential Equations). When considering the discrete subset
of Simulink, it can be used to automatically produce embedded code,
accelerating code development while minimizing the introduction of bugs
during the design.

Another industrial language is ANSYS Scade and its associated academic
companion Lustre. While Scade resemble to the discrete subset of
Simulink with similar graphical objects to describe the model
components, Lustre is an equivalent yet textual language. Since the
toolchain relies on Lustre as an intermediate language, let us provides
some elements about its syntax and semantics.

.. _sec:lustre:

Lustre :cite:`DBLP:conf/popl/CaspiPHP87` :cite:`lustre2` and relationship to Simulink
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Lustre** is a synchronous language for modeling systems of synchronous
reactive components. Lustre code consists of set of nodes transforming
infinite streams of input flows as streams of output flows. A notion of
symbolic “abstract” universal clock is used to model system progress. In
Lustre, a node is defined as a set, ie. unordered, of stream equations,
with possible local variables denoting internal flows. Regular
arithmetic and comparison operators are lifted to sequences and are
evaluated at each time step. If-then-else constructs are functionals and
should be well typed: they build values instead of sequencing imperative
statements. Ie. a valid flow equation could be

**Stateful constructs.** Temporal operator , for *previous*, enables a
limited form of memory, allowing to read the value of a stream at the
previous instant. It is corresponds to the unit delay operator of
Simulink or to its Memory block. The arrow operator, know as
*follow-by*, allows to build a stream as the expression while specifying
the first value . A flow defined as will then correspond in Simulink to
a Unit Delay over flow with initial value . A node containing such
operators in its expressions is considered as *stateful*, meaning that
it does not act as a pure mathematical function but is fitted with an
internal state describing the current values for and whether it is in
its first time step or not.

The following Lustre node describes a simple program: a node that every
four computation steps activates its output signal, starting at the
third step. The input reinitializes this counter.

node counter(reset: bool) returns (active: bool); var a, b: bool; let a
= false -> (not reset and not (pre b)); b = false -> (not reset and pre
a); active = a and b; tel

In that example the streams and are local ones and defined by the two
first equations. Expressions within equations can also make calls to
other nodes. Different occurrences of call to the same stateful node
represent different instances of memories.

**Hierarchy and algebraic loops.** Nodes and calls form a hierarchy of
nodes comparable to the notion of subsystems in Simulink. Types and
clocks inference can guarantee, at compile time, that expressions and
function calls respect their type constraints and properly rely on
previous values to build current ones. For example the following
equations are accepted and produce an *algebraic loop* error: The same
definitions with either or would be typable and accepted by the
compiler. Note that Simulink manage to solve these errors dynamically,
when running simulation. The resolution of algebraic loop can either be
performed by inlining nodes, or through the introduction of a construct
acting as a buffer. While inlining preserves the semantics, introducing
a new memory does not. It is therefore important to address these
possible algebraic loop early in the process to master their resolution.

**Clocks and resets.** Another specific construct is the definition of
clocks and clocked expressions. Clocks are defined as enumerated types,
the simplest ones being boolean clocks. Expressions can then be clocked
with respect to such clock values: where is a boolean clock. In this
case the expression is only defined when variable is positive. Clocked
expressions can be gathered using operator:

x = merge c (true -> e1 when c) (false -> e2 when not c);

Expressions associated to each clock case have to be clocked
appropriately. The clocking phase of the compiler allows to check the
consistency of clocks definitions and their uses. Clocks can also be
used to reset a node in its initial state using the syntax . When holds
this instance of node is restored in its initial setting with all arrow
equations pointing to their left value. Recursively all callee of are
also reset. Again, one can see some similarities with the Enable
Subsystems of Simulink.

Extensions to model automata
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All of these frameworks provide extensions to express automata. In the
Matlab context, Stateflow can support the definition of such automata.
Stateflow is a toolbox developed by TheMathWorks that extends
Simulink :cite:`simulink` with an environment for modeling
and simulating state machines as reactive systems. A Stateflow diagram
can be included in a Simulink model as one of the blocks interacting
with other Simulink components using input and output signals. Stateflow
is a highly complex language with no formal semantics [1]_: its
semantics is only described through examples on TheMathWorks
website :cite:`stateflow` without any formal definition. A
Stateflow diagram has a hierarchical structure, which can be either
arranged in *parallel* in which all states are eventually executed,
following a specific order; or *sequentially*, in which states are
connected with transitions and only one of them can be active. The
occurrence of a signal or the computation of a new time step allows the
active state to evaluate transitions and can perform an unbounded number
of side effects over the automaton variables. In practice the use of
Stateflow in actual system has to be restricted to a limited number of
construct in order to guarantee, for example, the execution time of one
time step computation. The typical use is to rely on these automata to
build a set of boolean flows denoting the active mode of the system.
This boolean flow is then used in the regular Simulink model to drive
the computation.

The Scade/Lustre approaches also propose extensions with automata. In
this context, automata definition acts as a basic construct and can be
mixed with classical flow definitions. Therefore the content of a node
could define regular flows as well as automaton, i.e. hierarchical state
machines. Each automaton state is also defined with a Lustre node which
can, itself, contains regular flows and automaton. The semantics is very
constrained and specifies the notion of weak or strong transitions. A
single step computation can fire at most one weak and one strong
transition.

.. _sec:spec_means:

Means of expressing the axiomatics semantics: varieties of synchronous observers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

In :cite:`DBLP:journals/cacm/Hoare69`, “An Axiomatic Basis
for Computer Programming”, Hoare defines a deductive reasoning to
validate code level annotations. This paper introduces the concept of
Hoare triple :math:`\{ Pre \} code \{ Post \}` as a way to express the
semantics of a piece of code by specifying the postconditions
(:math:`Post`) that are guaranteed after the execution of the code,
assuming that a set of preconditions (:math:`Pre`) was satisfied. Hoare
supports a vision in which this axiomatic semantics is used as the
“ultimately definitive specification of the meaning of the language […],
leaving certain aspects undefined. [...] Axioms enable the language
designer to express its general *intentions* quite simply and directly,
without the mass of detail which usually accompanies algorithmic
descriptions.” When this pair :math:`(Pre, Post)` is associated to a
function, it can be interpreted as a function contract. In a more
general use of formal specification, the local reasoning about the
function makes the assumption :math:`Pre` but, when this function is
called, the precondition has to be guaranteed. Otherwise the function is
not fully specified and its behavior is not defined.

This idea has been naturally extended to synchronous dataflow languages
with the concept of synchronous
observer :cite:`DBLP:conf/amast/HalbwachsLR93` :cite:`Westhead96verificationof` :cite:`Rushby:SAS14`.
A synchronous observer encodes a predicate corresponding to the
postcondition of the Hoare triple. However since the semantics is not
expressed over values but flows of values, the principle of Hoare triple
has to be lifted to sequences of values.

.. math:: \{Pre(state, inputs) \} node(in,out) \{ Post(state, state', in , out)\}

 means

.. math::

   \square \left( \bigwedge \begin{array}{l}\mathcal{H} (Pre(state, input)) \\ node(state, state', in, out)\end{array}
     \implies
    Post(state, state', in, out) \right).

with :math:`\mathcal{H} (p) \triangleq \{` p has held since beginning
:math:`\}`. The operator :math:`\mathcal{H}` can be defined in Lustre
with the node :

node Sofar (in: bool) returns (out: bool); let out = in -> pre out and
in; tel

Such a synchronous contract is active when, at a given time step, all
the inputs and internal states, up to now, have satisfied the
precondition. It is valid if then the postcondition always applies.

Graphically speaking a synchronous observer is a subsystem that accesses
to some internal flows and computes a boolean output.
Figure \ :ref:`ref <fig:sl-simple-obs>` performs such a
computation and verifies that a specific relationship between its two
inputs is always valid.

.. raw:: latex

   \centering
.. _fig:sl-simple-obs:

.. figure:: /graphics/sl_synchronous_obs.jpg
   :alt: Simple synchronous observer as Simulink subsystem

   Simple synchronous observer as Simulink subsystem

In control theory we speak about an open-loop property: the property can
be expressed over the controller inputs, outputs or memories without
knowledge of the plant semantics.
Figure \ :ref:`ref <fig:cocospec-open>` presents the
association of such a synchronous observer, an open-loop property,
attached to a component element.

.. raw:: latex

   \centering

.. figure:: /graphics/cocospec-open.jpg
   :alt: Open-loop properties in a synchronous observer
   :name: fig:cocospec-open

   Open-loop properties in a synchronous observer

The content of the observer itself is left free and could be as complex
as required, depending on the complexity of the requirement it models.
While this notion is expressive enough and is capable of capturing all
kinds of requirements, it is sometimes more convenient to refine the
specification by expressing hypotheses, ie. the precondition of the
Hoare triples, or modes, conditional behavior depending on some
conditions.

In Lustre, recent works :cite:`Champion2016` proposed a
dedicated language to annotate Lustre model with a rich specification.
Figure \ :ref:`ref <fig:cocospec>` gives an example. The node
represents the mode logic of an aircraft controller, deciding whether
the autopilot is active or not. Its specification is described in a .
This contract can bind new variables but, more importantly, can specify
the precondition for that contract. Two mains postcondition are
expressed as well as four different modes. Each of these modes is
guarded by some conditions in the expressions, while a conditional
postcondition is specified. Last, in the actual Lustre node, the
contract is declared.
::

  contract ml ( altRequest, fpaRequest, deactivate : bool ; altitude,
              targetAlt : real ) 
  returns ( altEngaged, fpaEngaged : bool ) ; 
  let 
    var altRequested = switch(altRequest, deactivate) ; 
    var fpaRequested = switch(fpaRequest, deactivate) ; 
    var smallGap = abs(altitude - targetAlt) < 200.0 ; 
    assume altitude >= 0.0 ; guarantee targetAlt >= 0.0;
    guarantee not altEngaged or not fpaEngaged ; 
    mode guide210Alt (
        require smallGap ; 
        require altRequested; 
        ensure altEngaged ;
    ) ; 
    mode guide210FPA ( 
      require smallGap ; 
      require fpaRequested ; 
      require not altRequested; 
      ensure fpaEngaged; 
    ) ;
    mode guide180 ( 
      require not smallGap ; 
      require fpaRequested; 
      ensure fpaEngaged; 
    ) ; 
    mode guide170 (
      require not smallGap ; 
      require altRequested ; 
      require not fpaRequested;
      ensure altEngaged ; 
    ) ; 
  tel

:: 

  node ml ( altRequest, fpaRequest, deactivate : bool ; altitude,
  targetAlt : real ) 
  returns ( altEngaged, fpaEngaged : bool );
  (*@contract 
    import mlSpec ( altRequest, fpaRequest, deactivate : bool ;
                    altitude, targetAlt : real ) 
    returns ( altEngaged, fpaEngaged : bool );
  \*) 
  let ... tel

At Simulink level dedicated constructs, such as shown in
Fig. \ :ref:`ref <fig:sl-contracts_with_modes>`,
ease the definition of such model-based contracts.

.. raw:: latex

   \centering
.. _fig:sl-contracts_with_modes:

.. figure:: /graphics/kind_contract.jpg
   :alt: Modes as Simulink contracts

   Modes as Simulink contracts



Regarding the complexity of the synchronous observer node, it can
contain any legal Simulink or Scade/Lustre content. As an example,
Figure. \ :ref:`ref <fig:cocospec-closed>` presents a
template to support the expression of closed loop properties. This
observer contains both the plant model and a set of closed and open-loop
properties. Within that specification subsystem, observers can have
access to any flows, including the plant’ flows.

.. raw:: latex

   \centering

.. figure:: /graphics/cocospec-closed.jpg
   :alt: Encoding closed-loop properties in an observer
   :name: fig:cocospec-closed

   Encoding closed-loop properties in an observer

However, the insertion of the closed-loop specification node within a
model is not as convenient that it is for an open-loop property. The
open one could be defined only with probes, while the closed one needs,
maybe artificially, to reconstruct a feedback loop. This is presented in
Figure. \ :ref:`ref <fig:cocospec-closed-injection>`.
Note the occurrence of a *specification-based unit delay* to prevent the
creation of a spurious algebraic loop.

.. raw:: latex

   \centering

.. figure:: /graphics/cocospec-closed-injection.jpg
   :alt: Injecting closed-loop observers as model annotations
   :name: fig:cocospec-closed-injection

   Injecting closed-loop observers as model annotations

.. raw:: latex

   \clearpage

.. _sec:obs_vv:

Synchronous observers to support V&V activities
-----------------------------------------------

Once the specification is formalized, as regular Simulink components,
one can rely on them to support numerous verification and validation
activities. Let us look at the example in
Figure \ :ref:`ref <fig:example_spec>` to illustrate these
various uses.

.. raw:: latex

   \centering
.. _fig:example_spec:

.. figure:: /graphics/example_spec.jpg
   :alt: Example of a specification

   Example of a specification



This observer only focuses on a very local property: depending on some
conditions the controller switches between different control laws. This
property ensures that the switch is continuous. However simulations
performed on the whole controller leave no opportunity to evaluate the
validity of this specific property.
Figure \ :ref:`ref <fig:example_spec_run>` provides one
of such run. While one can consider that the global behavior is
acceptable, it is important to provide strong arguments for each
requirement.

.. raw:: latex

   \centering
.. _fig:example_spec_run:

.. figure:: /graphics/run_simple_ex.jpg
   :alt: One run of the example

   One run of the example



Synthesis of test oracles
"""""""""""""""""""""""""

Each formalized requirement acts as a test oracle. The synchronous
observer defines a predicate. Therefore its boolean output corresponds
to the validity of the expressed requirement.

This block is runable and can be used at various levels. As visible in
Figure \ :ref:`ref <fig:example_spec>` additional elements
could be added to the model to visualize the status of the property. In
this specific simulation run, the positive value of the output shows
that the property was valid during all the execution of that single
test.

In addition, since our framework is capable of producing C code for
Simulink models, the observer itself can be compiled to produce code.
This opens the opportunity to produce C level or binaries implementing
test oracles.

Computation of metrics regarding test suites
""""""""""""""""""""""""""""""""""""""""""""

When considering a large test suite, it is important to evaluate the
validity of each requirement for each test case but also to measure the
coverage of the specification. It can happen, for example, that a test
case does not activate a specification. The notion of modes in CoCoSpec
is appropriate: one need to provide figures regarding the evaluation of
each mode by a test suite.

The Figure \ :ref:`ref <fig:example_spec>` also provides
these elements as internal flows. Each simulation will produce some
numerical values denoting the activation of the property or some
meaningful values. In this specific case we compute the number of mode
switches, which was 34 is that run, as well as the maximal value of the
discontinuity, which was :math:`5\cdot 10^{-5}`.

Metrics and coverage of requirements can then be automatized, either at
model level, or at code level.

Supporting the generation of test cases
"""""""""""""""""""""""""""""""""""""""

Since the property is expressed in the same language as the model it can
be easily expressed in the intermediate language and, eventually in C.
For certain class of specifications, eg. blocks limited to boolean and
linear integer flows, satisfiability model checkers can search for
sequence of inputs activating a given mode or satisfying a given
condition. Synthesis of traces, ie. test case, containing real/floats
values is much more challenging and requires other techniques.

Consistency of specification
""""""""""""""""""""""""""""

Among the possibilities, let us mention also the evaluation or
verification of the consistency of the specification. At the contract
level, one can ensure that mode constraints are disjunctive or that the
mode partitioning is complete, ie. that their disjunction is always
valid.

One can also check the validity of assumes, requires, ensures statements
or evaluate whether the expressed predicates are compatible with
predicates expressed over sub-components.

.. raw:: latex

   \vfill

.. raw:: latex

   \vfill

.. [1]
   At least not provided as a reference by the tool provider.


.. bibliography:: /references.bib