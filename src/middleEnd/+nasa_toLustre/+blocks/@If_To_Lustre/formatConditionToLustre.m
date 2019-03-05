function [exp, status] = formatConditionToLustre(obj, cond, inputs_cell, data_map, parent, blk)
    %% new version of parsing Lustre expression.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %L = nasa_toLustre.ToLustreImport.L;
    %import(L{:})
    %display_msg(cond, MsgType.DEBUG, 'If_To_Lustre', '');
    expected_dt = 'bool';
    [exp, status] = ...
        nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.translate(obj, cond, parent, blk,data_map, inputs_cell, expected_dt, true, false, false);
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



