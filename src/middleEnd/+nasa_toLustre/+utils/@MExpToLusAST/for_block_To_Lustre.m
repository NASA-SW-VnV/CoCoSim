function [code, exp_dt, dim, extra_code] = for_block_To_Lustre(tree, args)
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
    should_be_abstracted = false;
    indexes = [];
    index_dt = '';
    try
        [index_expression, index_dt, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
            tree.index_expression, args);
        index_class = unique(cellfun(@(x) class(x), index_expression, 'UniformOutput', 0));
        if length(index_class) == 1 && ...
                (strcmp(index_class{1}, 'nasa_toLustre.lustreAst.IntExpr') || ...
                strcmp(index_class{1}, 'nasa_toLustre.lustreAst.RealExpr'))
            indexes = cellfun(@(x) x.value, index_expression, 'UniformOutput', 1);
        else
            should_be_abstracted = true;
        end
    catch
        should_be_abstracted = true;
    end
    %%
    if ~should_be_abstracted
        try
            [for_node] = nasa_toLustre.utils.MF2LusUtils.getStatementsBlockAsNode(...
                tree, args, 'FOR');
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'for_block_To_Lustre', '');
            should_be_abstracted = true;
        end
    end
    % 
    if should_be_abstracted
        [for_node] = nasa_toLustre.utils.MF2LusUtils.abstract_statements_block(...
            tree, args, 'FOR');
    end
    
    if isempty(for_node)
        return;
    end
    
    [call, oututs_Ids] = for_node.nodeCall();
    if length(oututs_Ids) > 1
        oututs_Ids = nasa_toLustre.lustreAst.TupleExpr(oututs_Ids);
    end
    
    if should_be_abstracted
        code{1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
    else
        index_id = nasa_toLustre.lustreAst.VarIdExpr(tree.index);
        for i = 1:length(indexes)
            index_v = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(indexes(i), index_dt);
            code{end+1} = nasa_toLustre.lustreAst.LustreEq(index_id, index_v);
            code{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
        end
    end
    
    for_node = for_node.pseudoCode2Lustre(args.data_map);
    MFUNCTION_EXTERNAL_NODES{end+1} = for_node;
end

