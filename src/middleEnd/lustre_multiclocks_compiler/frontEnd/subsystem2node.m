function [ main_node, external_nodes, external_libraries ] = subsystem2node( subsys_struct,  main_sampleTime, xml_trace)
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

% Initializing outputs
external_nodes = '';
main_node = '';
external_libraries = {};

% Adding lustre comments tracking the original path
origin_path = regexprep(subsys_struct.Origin_path, '(\\n|\n)', '--');
comment = sprintf('-- Original block name: %s', origin_path);

% creating node header
node_name = SLX2LusUtils.node_name_format(subsys_struct);
node_inputs = SLX2LusUtils.extract_node_InOutputs_withDT(subsys_struct, 'Inport', xml_trace);
node_outputs = SLX2LusUtils.extract_node_InOutputs_withDT(subsys_struct, 'Outport', xml_trace);

node_header = sprintf('node %s (%s)\n returns (%s);',...
    node_name, node_inputs, node_outputs);

% creating contract
contract = '-- Contract In progress';


% Body code
[body, variables_str, external_nodes, external_libraries] = write_body(subsys_struct, main_sampleTime, xml_trace); 

main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel',...
    comment, node_header, contract, variables_str, body);
end



function [body, variables_str, external_nodes, external_libraries] =...
    write_body(subsys, main_sampleTime, xml_trace)
variables_str = '';
body = '';
external_nodes = '';
external_libraries = {};


fields = fieldnames(subsys.Content);
fields = ...
    fields(cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));

for i=1:numel(fields)
    blk = subsys.Content.(fields{i});
    [b, status] = getWriteType(blk);
    if status
        continue;
    end
    b.write_code(subsys, blk, xml_trace);
    body = [body, b.getCode()];
    variables_str = [variables_str, char(MatlabUtils.strjoin(b.variables, '\n\t'))];
    external_nodes = [external_nodes, b.external_nodes];
    external_libraries = [external_libraries, b.external_libraries];
end
if ~isempty(variables_str)
    variables_str = ['var ' variables_str];
end
end


