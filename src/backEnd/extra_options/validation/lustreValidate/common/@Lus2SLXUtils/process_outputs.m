%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [x2, y2] = process_outputs(node_block_path, blk_outputs, ID, x2, y2, isBranch)
    if ~exist('isBranch', 'var')
        isBranch = 0;
    end
    for i=1:numel(blk_outputs)
        if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
        if isfield(blk_outputs(i), 'name')
            var_name = BUtils.adapt_block_name(blk_outputs(i).name, ID);
        else
            var_name = BUtils.adapt_block_name(blk_outputs(i), ID);
        end
        output_path = strcat(node_block_path,'/',var_name);
        output_input =  strcat(node_block_path,'/',var_name,'_In');
        add_block('simulink/Ports & Subsystems/Out1',...
            output_path,...
            'Position',[(x2+200) y2 (x2+250) (y2+50)]);
        if isBranch
            signal_cv_path = strcat(node_block_path,'/',var_name, '_copy');
            add_block('simulink/Signal Attributes/Signal Conversion',...
                signal_cv_path,...
                'Position',[(x2+100) y2 (x2+150) (y2+50)]);
            SrcBlkH = get_param(signal_cv_path,'PortHandles');
            DstBlkH = get_param(output_path, 'PortHandles');
            add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
            output_path = signal_cv_path;
        end

        add_block('simulink/Signal Routing/From',...
            output_input,...
            'GotoTag',var_name,...
            'TagVisibility', 'local', ...
            'Position',[x2 y2 (x2+50) (y2+50)]);

        SrcBlkH = get_param(output_input,'PortHandles');
        DstBlkH = get_param(output_path, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    end
end

