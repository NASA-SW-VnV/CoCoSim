%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [x2, y2] = link_subsys_outputs( parent_path, subsys_block_path, outputs, var,node_name,  x2, y2, isBranch, branchIdx)
    [~, ID, ~] = fileparts(subsys_block_path);%BUtils.adapt_block_name(var{1});
    SrcBlkH = get_param(subsys_block_path,'PortHandles');
    for i=1:numel(outputs)
        output = outputs(i);
        output_adapted = BUtils.adapt_block_name(output,node_name);
        if exist('isBranch','var') && isBranch
            output_adapted = strcat(output_adapted, '_branch_', num2str(branchIdx));
        end
        output_path = strcat(parent_path,'/',ID,'_out',num2str(i));
        add_block('simulink/Signal Routing/Goto',...
            output_path,...
            'GotoTag',output_adapted,...
            'TagVisibility', 'local', ...
            'Position',[(x2+300) y2 (x2+350) (y2+50)]);
        y2 = y2 + 150;
        DstBlkH = get_param(output_path, 'PortHandles');
        add_line(parent_path, SrcBlkH.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
    end
end
