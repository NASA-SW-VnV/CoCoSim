%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [model_inputs_struct, inputEvents_names] = get_model_inputs_info(model_full_path)
    %TODO: Need to be optimized
    model_inputs_struct = [];
    try
        load_system(model_full_path);
    catch ME
        error(ME.getReport());
        return;
    end
    [~, slx_file_name, ~] = fileparts(model_full_path);
    rt = sfroot;
    m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', slx_file_name);
    events = m.find('-isa', 'Stateflow.Event');
    inputEvents = events.find('Scope', 'Input');
    inputEvents_names = inputEvents.get('Name');
    code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
    warning off;
    evalin('base',code_on);
    block_paths = find_system(slx_file_name, 'SearchDepth',1, 'BlockType', 'Inport');
    for i=1:numel(block_paths)
        block = block_paths{i};
        block_ports_dts = get_param(block, 'CompiledPortDataTypes');
        DataType = block_ports_dts.Outport;
        dimension_struct = get_param(block,'CompiledPortDimensions');
        dimension = dimension_struct.Outport;
        if numel(dimension)== 2 && dimension(1)==1
            dimension = dimension(2);
        elseif numel(dimension) >= 3
            dimension = dimension(2:end);
        end
        width_struct = get_param(block,'CompiledPortWidths');
        width = width_struct.Outport;
        model_inputs_struct = [model_inputs_struct, struct('name',BUtils.naming_alone(block),...
            'datatype', DataType, 'dimension', dimension, ...
            'width', width)];

    end
    code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
    evalin('base',code_off);
    %warning on;
end
