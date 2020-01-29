function [code, exp_dt, dim, extra_code] = while_block_To_Lustre(tree, args)
    % end is used for Array indexing: e.g., x(end-1), x(1:end) ... 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    global MFUNCTION_EXTERNAL_NODES
    
    
    code = {};
    exp_dt = '';
    dim = [];
    extra_code = {};
    %%
    [while_node] = nasa_toLustre.utils.MF2LusUtils.abstract_statements_block(...
        tree, args, 'WHILE');
    if isempty(while_node)
        return;
    end
    MFUNCTION_EXTERNAL_NODES{end+1} = while_node;
    [call, oututs_Ids] = while_node.nodeCall();
    if length(oututs_Ids) == 1
    code{1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
    else
        code{1} = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.TupleExpr(oututs_Ids), call);
    end
end

