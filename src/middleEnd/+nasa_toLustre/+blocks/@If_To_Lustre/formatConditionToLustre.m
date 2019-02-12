
%% new version of parsing Lustre expression.
function [exp, status] = formatConditionToLustre(obj, cond, inputs_cell, data_map, parent, blk)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    %display_msg(cond, MsgType.DEBUG, 'If_To_Lustre', '');
    expected_dt = 'bool';
    [exp, status] = ...
        MExpToLusAST.translate(obj, cond, parent, blk,data_map, inputs_cell, expected_dt, true, false);
    if iscell(exp) 
        if numel(exp) == 1
            exp = exp{1};
        elseif numel(exp) > 1
            exp = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, exp);
        end
    end
    if status
        display_msg(sprintf('Block %s is not supported', HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'If_To_Lustre.formatConditionToLustre', '');
        return;
    end
end



