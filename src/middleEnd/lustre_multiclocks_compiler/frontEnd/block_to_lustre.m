function [ main_node, external_nodes ] = block_to_lustre( subsys_struct,  main_sampleTime, xml_trace)
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

main_node = '';
external_nodes = '';

%Lustre comments
comment_format = '--Block path : %s\n';
comment = sprintf(comment_format, subsys_struct.Origin_path);

%Node header
header_format = 'node %s ( %s )\n returns ( %s );\n';
node_name = SLX2LusUtils.node_name_format(subsys_struct);
inputs_str = '';
outputs_str = '';
header = sprintf(header_format, node_name, inputs_str, outputs_str);

%Node variables
vars = '';

%body
body = 'let\n tel\n';

main_node = [comment, header, vars, body];
end

