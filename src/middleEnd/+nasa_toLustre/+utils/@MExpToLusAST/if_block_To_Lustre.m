function [code, exp_dt, dim] = if_block_To_Lustre(tree, args)
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
    if_cond = args.if_cond;
    args.expected_lusDT = 'bool';
    [condition, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.condition, args);
    args.expected_lusDT = '';
    
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
    args.data_map(cond_name) = s;
    
    if length(tree.statements) > 1
        for i=1:length(tree.statements)
            args.if_cond = cond_ID;
            [statements, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.statements{i}, args);
            code = MatlabUtils.concat(code, statements);
        end
    else
        args.if_cond = cond_ID;
        [statements, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
            tree.statements, args);
        code = MatlabUtils.concat(code, statements);
    end
    
    not_condID = nasa_toLustre.lustreAst.UnaryExpr(...
        nasa_toLustre.lustreAst.UnaryExpr.NOT, cond_ID);
    %% TODO: why the length(tree.else_block.statements) > 1, discuss it with Hamza
    if isfield(tree.else_block, 'statements')
        if length(tree.else_block.statements) > 1
            for i=1:length(tree.else_block.statements)
                args.if_cond = not_condID;
                [else_block, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    tree.else_block.statements(i), args);
                code = MatlabUtils.concat(code, else_block);
            end
        else
            args.if_cond = not_condID;
            [else_block, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.else_block.statements, args);
            code = MatlabUtils.concat(code, else_block);
        end
    end
    
    
    exp_dt = '';
    dim = [];
end

