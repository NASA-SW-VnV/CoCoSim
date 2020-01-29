%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

function  [x2, y2] = process_reset(node_block_path, blk_exprs, var, node_name, x2, y2)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end

    ID = BUtils.adapt_block_name(var{1});
    lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
    lhs_path = BUtils.get_unique_block_name(strcat(node_block_path,'/',ID, '_lhs'));
    rhs_path = BUtils.get_unique_block_name(strcat(node_block_path,'/',ID,'_rhs'));


    rhs_name = blk_exprs.(var{1}).rhs;
    add_block('simulink/Commonly Used Blocks/Constant',...
        rhs_path,...
        'Value',rhs_name,...
        'Position',[x2 y2 (x2+50) (y2+50)]);
    set_param(rhs_path, 'OutDataTypeStr', 'boolean');


    add_block('simulink/Signal Routing/Goto',...
        lhs_path,...
        'GotoTag',lhs_name,...
        'TagVisibility', 'local', ...
        'Position',[(x2+100) y2 (x2+150) (y2+50)]);

    SrcBlkH = get_param(rhs_path,'PortHandles');
    DstBlkH = get_param(lhs_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end
