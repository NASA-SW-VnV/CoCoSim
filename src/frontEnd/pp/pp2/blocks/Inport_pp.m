function Inport_pp( new_model_base )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display_msg('Processing Inport blocks', MsgType.INFO, 'PP', '');

inport_list = find_system(new_model_base,'LookUnderMasks', 'all', 'BlockType','Inport');
model = regexp(new_model_base,'/','split');
model = model{1};
if ~isempty(inport_list)
    warning off;
    code_on=sprintf('%s([], [], [], ''compile'')', model);
    eval(code_on);
    port_map = containers.Map();
    for i=1:length(inport_list)
        port_dt = get_param(inport_list{i}, 'CompiledPortDataTypes');
        port_map(inport_list{i}) = port_dt.Outport;
    end
    code_off = sprintf('%s([], [], [], ''term'')', model);
    eval(code_off);
    warning on;
    for i=1:length(inport_list)
        dt = port_map(inport_list{i});
        if strcmp(dt, 'auto')
            continue;
        end
        try
            set_param(inport_list{i}, 'OutDataTypeStr', dt{1})
        catch
            % case of bus signals is ignored.
        end
    end
end
end