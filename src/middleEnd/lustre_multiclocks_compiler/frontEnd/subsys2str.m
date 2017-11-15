function [ main_node, external_nodes ] = subsys2str( subsys_struct,  main_sampleTime, xml_trace)
%BLOCK_TO_LUSTRE create a lustre node for every Simulink subsystem within
%subsys_struc.
%INPUTS:
%   subsys_struct: The internal representation of the subsystem.
%   main_clock   : The model sample time.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

variablesAlreadyCurrented = {};
body = StringWriter();
body.addcr('let');


end

