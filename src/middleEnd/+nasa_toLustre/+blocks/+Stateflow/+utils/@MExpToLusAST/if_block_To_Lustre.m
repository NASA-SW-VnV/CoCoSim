function [code, exp_dt, dim] = if_block_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun, if_cond)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    persistent counter;
    if isempty(counter)
        counter = 0;
    end
    code = {};
    [condition, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.condition,...
        parent, blk, data_map, inputs, 'bool', ...
        isSimulink, isStateFlow, isMatlabFun, []);
    cond_name = strcat('ifCond_', num2str(counter), strrep(num2str(rand(1)), '0.', '_'));
    counter = counter + 1;
    cond_ID = nasa_toLustre.lustreAst.VarIdExpr(cond_name);
    if isempty(if_cond)
        code{end+1} = nasa_toLustre.lustreAst.LustreEq(cond_ID, condition);
    else
        code{end+1} = nasa_toLustre.lustreAst.LustreEq(cond_ID, ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.AND, if_cond, condition));
    end
    s = struct('Name', cond_name, 'LusDatatype', 'bool', 'DataType', 'boolean', ...
        'CompiledType', 'boolean', 'InitialValue', '0', ...
        'ArraySize', '1 1', 'CompiledSize', '1 1', 'Scope', 'Local', ...
        'Port', '1');
    data_map(cond_name) = s;
    
    if length(tree.statements) > 1
        for i=1:length(tree.statements)
            [statements, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.statements{i},...
                parent, blk, data_map, inputs, expected_dt, ...
                isSimulink, isStateFlow, isMatlabFun, cond_ID);
            code = MatlabUtils.concat(code, statements);
        end
    else
        [statements, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.statements,...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun, cond_ID);
        code = MatlabUtils.concat(code, statements);
    end
    
    not_condID = nasa_toLustre.lustreAst.UnaryExpr(...
        nasa_toLustre.lustreAst.UnaryExpr.NOT, cond_ID);
    if isfield(tree.else_block, 'statements')
        if length(tree.else_block.statements) > 1
            for i=1:length(tree.else_block.statements)
                [else_block, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.else_block.statements(i),...
                    parent, blk, data_map, inputs, expected_dt, ...
                    isSimulink, isStateFlow, isMatlabFun, not_condID);
                code = MatlabUtils.concat(code, else_block);
            end
        else
            [else_block, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.else_block.statements,...
                parent, blk, data_map, inputs, expected_dt, ...
                isSimulink, isStateFlow, isMatlabFun, not_condID);
            code = MatlabUtils.concat(code, else_block);
        end
    end
    
    
    exp_dt = '';
    dim = [];
end

