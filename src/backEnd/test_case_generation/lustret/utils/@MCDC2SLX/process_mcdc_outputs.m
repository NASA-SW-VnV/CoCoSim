%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [x2, y2] = process_mcdc_outputs(node_block_path, blk_outputs, ID, x2, y2)
    if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
    for i=1:numel(blk_outputs)
        if y2 < 30000; y2 = y2 + 150; else x2 = x2 + 500; y2 = 100; end
        if isfield(blk_outputs(i), 'name')
            var_name = BUtils.adapt_block_name(blk_outputs(i).name, ID);
        else
            var_name = BUtils.adapt_block_name(blk_outputs(i), ID);
        end
        output_path = strcat(node_block_path,'/',var_name);
        output_input =  strcat(node_block_path,'/',var_name,'_In');
        add_block('pp_lib/MCDC_Counter',...
            output_path,...
            'Position',[(x2+200) y2 (x2+350) (y2+50)]);
        try
            set_param(fullfile(output_path, 'ToWorkspace'),...
                'VariableName', var_name);
        catch
            display_msg(['couldn''t find ToWorkspace block in ' output_path],...
                MsgType.DEBUG, 'MCDC2SLX', '');
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