%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function  [x2, y2] = process_functioncall(node_block_path, blk_exprs, var, node_name, x2, y2)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end

    ID = BUtils.adapt_block_name(var{1});
    fcn_path = strcat(node_block_path,'/',ID,'_call');
    fun_name = BUtils.adapt_block_name(blk_exprs.(var{1}).name);
    fun_library = blk_exprs.(var{1}).library;

    status = Lus2SLXUtils.add_funLibrary_path(fcn_path, fun_name, fun_library, [(x2+100) y2 (x2+250) (y2+50)]);
    if status
        return;
    end

    SrcBlkH = get_param(fcn_path,'PortHandles');
    y3=y2;
    for i=1:numel(blk_exprs.(var{1}).lhs)
        output = blk_exprs.(var{1}).lhs(i);
        output_adapted = BUtils.adapt_block_name(output, node_name);
        output_path = BUtils.get_unique_block_name(...
            strcat(node_block_path,'/',ID,'_out', num2str(i)));
        add_block('simulink/Signal Routing/Goto',...
            output_path,...
            'GotoTag',output_adapted,...
            'TagVisibility', 'local', ...
            'Position',[(x2+300) y2 (x2+350) (y2+50)]);
        DstBlkH = get_param(output_path, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
        y2 = y2 + 150;
    end
    y2 = y3;
    DstBlkH = get_param(fcn_path,'PortHandles');
    for i=1:numel(blk_exprs.(var{1}).args)
        input = blk_exprs.(var{1}).args(i).value;
        input_type = blk_exprs.(var{1}).args(i).type;
        input_adapted = BUtils.adapt_block_name(input, node_name);
        input_path = BUtils.get_unique_block_name(...
            strcat(node_block_path,'/',ID,'_In',num2str(i)));
        if strcmp(input_type, 'constant')
            add_block('simulink/Commonly Used Blocks/Constant',...
                input_path,...
                'Value', input,...
                'Position',[x2 y2 (x2+50) (y2+50)]);
            %         set_param(input_path, 'OutDataTypeStr','Inherit: Inherit via back propagation');
            dt = blk_exprs.(var{1}).args(i).datatype;
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
                'GotoTag',input_adapted,...
                'TagVisibility', 'local', ...
                'Position',[x2 y2 (x2+50) (y2+50)]);
        end
        y2 = y2 + 150;
        SrcBlkH = get_param(input_path,'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(i), 'autorouting', 'on');
    end
end

