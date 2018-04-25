function InportShadow_pp( new_model_base )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display_msg('Processing InportShadow blocks', MsgType.INFO, 'PP', '');

inportShadow_list = find_system(new_model_base,'LookUnderMasks', 'all', 'BlockType','InportShadow');
model = regexp(new_model_base,'/','split');
model = model{1};
if ~isempty(inportShadow_list)
    for i=1:numel(inportShadow_list)
        display_msg(sprintf('Processing InportShadow block %s',inportShadow_list{i}),...
            MsgType.INFO, 'PP', '');
        parent = get_param(inportShadow_list{i}, 'Parent');
        origInport = find_system(parent,'SearchDepth',1, ...
            'BlockType', 'Inport', ...
            'Port',get_param(inportShadow_list{i},'Port'));
        if isempty(origInport)
            continue;
        end
        origInport = origInport{1};
        inportShadowHandles = get_param(inportShadow_list{i},'PortHandles');
        line = get_param(inportShadowHandles.Outport(1), 'line');
        dstPortHandle = get_param(line, 'DstPortHandle');
        origInportHandles = get_param(origInport,'PortHandles');
        delete_line(line);
        add_line(parent, origInportHandles.Outport(1), dstPortHandle, 'autorouting', 'on');
        delete_block(inportShadow_list{i});
    end
end
end