function [exp, status] = formatConditionToLustre(obj, cond, inputs_cell, data_map, parent, blk)
    %% new version of parsing Lustre expression.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %display_msg(cond, MsgType.DEBUG, 'If_To_Lustre', '');
    expected_dt = 'bool';
    args.blkObj = obj;
    args.blk = blk;
    args.parent = parent;
    args.data_map = data_map;
    args.inputs = inputs_cell;
    args.expected_lusDT = expected_dt;
    args.isSimulink = true;
    args.isStateFlow = false;
    args.isMatlabFun = false;
    [exp, status] = ...
        nasa_toLustre.utils.MExpToLusAST.translate(cond, args);
    if iscell(exp) 
        if numel(exp) == 1
            exp = exp{1};
        elseif numel(exp) > 1
            exp = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, exp);
        end
    end
    if status
        display_msg(sprintf('Block %s is not supported', HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'If_To_Lustre.formatConditionToLustre', '');
        return;
    end
end



