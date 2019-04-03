%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [x2, y2] = process_operator(node_block_path, blk_exprs, var, node_name, x2, y2)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;

    ID = BUtils.adapt_block_name(var{1});
    lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
    lhs_path = strcat(node_block_path,'/',ID, '_lhs');
    op_path = strcat(node_block_path,'/',ID,'_operator');
    operator = blk_exprs.(var{1}).name;

    dt = blk_exprs.(var{1}).args(1).datatype;
    if isstruct(dt) && isfield(dt, 'kind')
        dt = dt.kind;
    end
    if strcmp(dt, 'bool')
        dt =  'boolean';
    elseif strcmp(dt, 'int')
        dt =  'int32';
    elseif strcmp(dt, 'real')
        dt =  'double';
    end
    Lus2SLXUtils.add_operator_block(op_path, operator,x2 ,y2, dt);

    add_block('simulink/Signal Routing/Goto',...
        lhs_path,...
        'GotoTag',lhs_name,...
        'TagVisibility', 'local', ...
        'Position',[(x2+300) y2 (x2+350) (y2+50)]);
    SrcBlkH = get_param(op_path,'PortHandles');
    DstBlkH = get_param(lhs_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');

    DstBlkH = get_param(op_path,'PortHandles');
    for inport_number=1:numel(blk_exprs.(var{1}).args)
        local_var = blk_exprs.(var{1}).args(inport_number).value;
        local_var_adapted = BUtils.adapt_block_name(local_var, node_name);
        input_path = strcat(node_block_path,'/',ID,'_rhs_',num2str(inport_number));
        if strcmp(blk_exprs.(var{1}).args(inport_number).type, 'constant')
            add_block('simulink/Commonly Used Blocks/Constant',...
                input_path,...
                'Value', local_var,...
                'Position',[x2 y2 (x2+50) (y2+50)]);
            %         set_param(input_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
            dt = blk_exprs.(var{1}).args(inport_number).datatype;
            if isstruct(dt) && isfield(dt, 'kind')
                dt = dt.kind;
            end
            if strcmp(dt, 'bool')
                set_param(input_path, 'OutDataTypeStr', 'boolean');
            elseif strcmp(dt, 'int')
                set_param(input_path, 'OutDataTypeStr', 'int32');
            elseif strcmp(dt, 'real')
                set_param(input_path, 'OutDataTypeStr', 'double');
            end
        else
            add_block('simulink/Signal Routing/From',...
                input_path,...
                'GotoTag',local_var_adapted,...
                'TagVisibility', 'local', ...
                'Position',[x2 y2 (x2+50) (y2+50)]);
        end
        y2 = y2 + 150;
        SrcBlkH = get_param(input_path,'PortHandles');

        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(inport_number), 'autorouting', 'on');
    end

end

