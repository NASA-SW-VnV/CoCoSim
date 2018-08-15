Back-End
========
Back-ends cover the main capabilities of framework. Most back-end rely
on the intermediate representation expressed as a Lustre model to
perform analyzes or compilation of that Lustre models and provide back
information at Simulink level.

For the moment CoCoSim is offering the following features: verification
enfines (cf. Sect. \ `0.1 <#sec:bk-end:verif>`__), code generation (cf.
Sect. \ `0.2 <#sec:bk-end:codegen>`__), invariant generation (cf.
Sect. \ `0.3 <#sec:bk-end:invariant_gen>`__), test-case generation and
coverage evaluation (cf. Sect. \ `0.4 <#sec:bk-end:tests>`__), Support
of specification, including Lustre to Simulink translation (cf.
Sect. \ `0.5 <#sec:bk-end:spec>`__), compilation validation (cf.
Sect. \ `0.6 <#sec:bk-end:validation>`__), and code analysis (cf.
Sect. \ `0.7 <#sec:bk-end:codeverif>`__).

As mentioned in the introduction, the goal of the framework is to ease
the application of formal methods for Simulink-based systems. The
backends are introduced and linked to the platform in a very generic
way. While is built mainly around a specified set of tools, additional
ones can be easily locally linked or even distributed as extensions.

.. _sec:bk-end:verif:

Verification
------------

Takes as input the formal language generated at the Middle-end step
(e.g. Lustre code) and performs safety analysis of the provided property
using one of model-checkers:
`Zustre <https://github.com/coco-team/zustre>`__ or
`Kind2 <http://kind2-mc.github.io/kind2/>`__. More model-checkers can be
integrated in the tool. The result of the safety analysis is reported
back to the Simulink environment. In case the property supplied is
falsified, CoCoSim provides means to simulate the counterexample trace
in the Matlab environment. Otherwise, in case of success, proof evidence
expressed as generated invariant can also be propagated back at
model-level as synchronous observers.

.. _sec:bk-end:codegen:

Code Generation
---------------

CoCoSim generates C, Rust or Lustre code from Simulink model. This
compilation process is validated by equivalence testing and equivalence
checking. See section `[sec:validation] <#sec:validation>`__.

.. _sec:bk-end:invariant_gen:

Invariants Generation
---------------------

-  Using Zustre: Zustre is a PDR-based tool, while analyzing Simulink
   model requirements, Zustre can produce a counter-example in case of
   failure, but also returns a set of invariants in case of success.
   These invariants can be expressed as runnable evidence in the
   Simulink level. They are expressed as a set of local invariants that
   could be attached to Simulink subsystems.

-  Using IKOS: We try in this work in progress to generate invariants in
   the Simulink level using Abstract Interpretation using
   `IKOS <https://ti.arc.nasa.gov/opensource/ikos/>`__ tool. They will
   be expressed as a set of local invariants that could be attached to
   each Simulink subsystems.

.. _sec:bk-end:tests:

Test-Case Generation
--------------------

The framework can rely on various methods to synthesize test cases. We
elaborate here on some approaches and provide elements explaining the
performed computation. All of these techniques rely on a model-checker
such as Kind2 or Zustre to perform bounded model-checking. A property,
or, more precisely its negation, is given to the tool and the transition
relation is unrolled until the property becomes invalid. The resulting
so-called counter-example is a test case that activates the property,
eventually. This unrolling process is called BMC: bounded
model-checking.

Figure \ `[fig:test_gen] <#fig:test_gen>`__ presents the set of
approaches that can be run at Lustre level and then propagated back as
test case at the Simulink level.

Specification based test generation
"""""""""""""""""""""""""""""""""""

A first natural use of BMC is to encode the contracts as targets.
Interesting elements could be active states for modes, or transitions
from one mode to another. One could also generate multiple test cases
for each specification by adding more criteria, for example range
conditions for values.

.. _sec:mutation:

Mutation based test generation
""""""""""""""""""""""""""""""

In the following we denote by *mutant* a mutated model or mutated
implementation where a single mutation has been introduced. The
considered mutation does not change the control flow graph or the
structure of the semantics but could either: (i) perform arithmetic,
relational or boolean operator replacement; or (ii) introduce additional
delay (pre operator in Lustre) – note that this could produce a program
with initialization issues - or (iii) negate boolean variable or
expressions; or (iv) replace constants.

Such generation of mutants has been implemented as an extension to our
Lustre to C compiler. The latter can now generate a set of mutant Lustre
models from the original Lustre model. Once mutants are generated and
the coverage-based test suite is computed, we can evaluate the number of
mutants killed by the test suite. This evaluation is performed at the
binary level, once the C code has been obtained from the compilation of
the mutant. In this setting, the source Lustre file acts as an oracle,
i.e. a reference implementation. Any test, that shows a difference
between a run of the original model compiled and a mutation of it,
allows to kill this mutant.

In the litterature, mutants are mainly used to evaluate the quality of a
test suite, allowing to compare test suites. In our case, the motivation
is different, we aim at providing the user with a test suite related to
its input model. This test suite covers the model behavior in order to
show that the compiler doesn’t introduce bugs. A test suite achieving a
good coverage of the code but unable to kill lots of mutant would not
show that the compiler did a good job. Indeed any unkilled mutant would
then be as good as the initial model while in practice they are
different. We have therefore to introduce new tests to kill those
mutants unkilled by the existing test suite.

We rely on the BMC to compute such a trace between the two versions of
the Lustre model. It may happen that the solver does not terminate or
return a usable output. First the BMC engine may not be capable of
generating a counter-example trace – i.e., the condition used might be
an invariant. Second the difference between :math:`out`, the original
output, and :math:`out'`, the mutated one, may be unobservable. The
latter is possible in mutated programs where the mutation does not
impact the observed output. For example, a condition :math:`a \lor b`
was always true because of :math:`b` while the mutation was performed in
the computation of :math:`a`. In this case the mutation is unobservable
and it is here related to dead code. This kind of mutation-based test
suite reinforcement is also able to detect some of those programmming
issues of the input model. In practice, our algorithm tries both to find
a trace showing the different between :math:`out` and :math:`out'` but
also to prove their equivalence. The latter case would then exhibit some
issues solely related to the input model, with no relevance to our
problem.

Coverage-based test generation
""""""""""""""""""""""""""""""

Usually the quality of a test suite is measured with its capability to
fulfill a given coverage criteria. Depending on the criticality of the
considered system the coverage criteria is more or less difficult to
meet. Among the various coverage criteria, the Modified
Condition/Decision Coverage (MC/DC) is recognized, with respect to
testing the usefulness and influence of each model artifact, as the
strongest and therefore the most costly to achieve.

can generate or complement a test suite to meet such a coverage. The
approach is the following: each condition is expressed as a dedicated
predicate; then we rely on BMC to generate a test case that activates
this condition. Let us develop how one can express the MC/DC criterion
as a predicate over node variables. First, we need an external procedure
which can extract the decision predicates from the source code. This
analysis generates a list of such conditions, eg. all boolean flow
definitions.

Coverage of each decision predicate is checked in isolation, against a
given global set of test cases. The principle is the following: from a
decision :math:`P(c_1,\ldots,c_n)` where the :math:`c_i`\ ’s are a set
of atomic conditions over the variables :math:`\tilde{s}`,
:math:`\tilde{in}` and :math:`\tilde{out}`, we have to exert the value
of each condition :math:`c_i` with respect to the global truth value of
:math:`P`, the other conditions :math:`c_{j\neq i}` being left
untouched. Precisely, we have to find two test cases  [1]_ for which, in
the last element of the trace, :math:`c_i` is respectively assigned to
:math:`False` and :math:`True`. Then, for each such test case, blindly
changing the value of :math:`c_i` should also change the global
predicate value. Formally, for a given decision
:math:`P(c_1,\ldots,c_n)`, the set of predicates describing the last
element of its covering traces is:

.. math::

   \label{eq:mcdc_smt}
   \left\{
   \begin{array}{l}
    c_i \land (P(c_1, \ldots, c_n) \oplus P(c_1, \ldots, c_{i-1}, \neg c_i, c_{i+1},\ldots, c_n))\ ,\\
   \neg c_i \land (P(c_1, \ldots, c_n) \oplus P(c_1, \ldots, c_{i-1}, \neg c_i, c_{i+1},\ldots, c_n))\\
   \end{array}\right\}
   _{i \in 1..n}

Note that the process may not succeed for each condition since the
property can be (1) unreachable or (2) undecidable to the SMT solver
behind the BMC analyzer.

.. raw:: latex

   \centering

.. figure:: /graphics/arch_test.*
   :alt: Combinaison of approaches to support test generation.

   Combinaison of approaches to support test generation.

[fig:test_gen]

.. _sec:bk-end:spec:

Lustre to Simulink
------------------

This back-end is interested in translating any Lustre code to pure
Simulink. It has many uses. We use this compilation process for our
compiler validation. See section `[sec:validation] <#sec:validation>`__.
It can also be used to annotate Simulink models with specification
written as Lustre models.

.. _sec:bk-end:validation:

Compiler Validation
-------------------

This back-end is interested in validating the compiler from Simulink to
Lustre. See section `[sec:validation] <#sec:validation>`__.

.. _sec:bk-end:codeverif:

Design error detection using IKOS
---------------------------------

Detect Design Errors using abstract interpretation
(`IKOS <https://ti.arc.nasa.gov/opensource/ikos/>`__). We are interested
in detecting the following Design errors:

-  Integer overflow.

-  Division by zero.

-  Dead logic.

-  Out of bound array access.

-  Derived Ranges of signals : (the interval approximation [a, b] of a
   signal x).

.. [1]
   In practice, a single test case may cover both cases, at different
   steps of the trace.
