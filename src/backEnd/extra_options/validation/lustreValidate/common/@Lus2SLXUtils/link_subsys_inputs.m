%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [x2, y2] = link_subsys_inputs( parent_path, subsys_block_path, inputs, var, node_name, x2, y2)
    [~, ID, ~] = fileparts(subsys_block_path);%BUtils.adapt_block_name(var{1});
    DstBlkH = get_param(subsys_block_path,'PortHandles');
    for i=1:numel(inputs)
        input = inputs(i).name;
        input_adapted = BUtils.adapt_block_name(input, node_name);
        input_path = BUtils.get_unique_block_name(...
            strcat(parent_path,'/',ID,'_In',num2str(i)));
        add_block('simulink/Signal Routing/From',...
            input_path,...
            'GotoTag',input_adapted,...
            'TagVisibility', 'local', ...
            'Position',[x2 y2 (x2+50) (y2+50)]);
        y2 = y2 + 150;
        SrcBlkH = get_param(input_path,'PortHandles');
        add_line(parent_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
    end
end
