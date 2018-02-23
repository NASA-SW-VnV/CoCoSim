function inport_process( new_model_base )

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
        set_param(inport_list{i}, 'OutDataTypeStr', dt{1})
    end
end
end