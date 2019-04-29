CoCoSim
=======

CoCoSim is an automated analysis and code generation framework for
Simulink and Stateflow models. Specifically, CoCoSim can be used to
verify automatically user-supplied safety requirements. Moreover,
CoCoSim can be used to generate C and/or Rust code. 
CoCoSim uses various model checkers for verification (Zustre, Kind2, JKind).
CoCoSim is currently under development. We welcome any feedback and bug report.

License
-------

CoCoSim has been released under the NASA Open Source Agreement.

Contact
-------

hamza.bourbouh@nasa.gov

Release notes
-------------

See [RELEASE_NOTES.md](RELEASE_NOTES.md)

Troubleshooting
---------------

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)


Installation
------------

See [INSTALL.md](INSTALL.md)



### Launching

+ Launch Matlab(c)
+ Navigate to `cocosim/`
+ Just run the file ```start_cocosim```
+ Make sure to have one of the backround solvers installed (e.g. Zustre, Kind2 and or JKind)
+ You can now open your Simulink model, e.g. ```open test/properties/safe_1.mdl```

## # Example

1. To test a safe property: `open test/properties/safe_1.mdl`
2. Under the `Tools` menu choose `Verify with ...` and then `Kind2` (or JKind if you are under Windows OS).
3. To test an unsafe property (which also provide a counterexample):
   `open test/properties/unsafe_1.mdl`

More information about CoCoSim can be found in `doc` folder


## Developers

* Lead Developer: [Hamza Bourbouh](https://ti.arc.nasa.gov/profile/bourbouh/)

* Pierre-Loic Garoche (Onera - France), Claire Pagetti (Onera - France), Eric
  Noulard (Onera - France), Thomas Loquen (Onera - France), Xavier
  Thirioux (ENSEEIHT - France)

* Past Contributors: [Temesghen Kahsai](http://www.lememta.info/)
, Arnaud Dieumegard.


## Acknowledgments and Disclaimers

CoCoSim is partially funded by:

   * NASA NRA NNX14AI09G
   * NSF award 1136008
