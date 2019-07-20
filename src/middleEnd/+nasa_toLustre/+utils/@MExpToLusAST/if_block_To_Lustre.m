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
    
    % statements
    if isstruct(tree.statements)
        tree_statements = arrayfun(@(x) x, tree.statements, 'UniformOutput', 0);
    else
        tree_statements = tree.statements;
    end
    args.if_cond = cond_ID;
    for i=1:length(tree_statements)
        [statements_code, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
            tree_statements{i}, args);
        code = MatlabUtils.concat(code, statements_code);
    end
    
    
    % elseif
    if ~isempty(tree.elseif_blocks)
        for i=1:length(tree.elseif_blocks)
            elif = tree.elseif_blocks(i);
            cond_name = strcat('ifCond_', num2str(counter), strrep(num2str(rand(1)), '0.', '_'));
            counter = counter + 1;
            new_cond_ID = nasa_toLustre.lustreAst.VarIdExpr(cond_name);
            [condition, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                elif.condition, args);
            code{end+1} = nasa_toLustre.lustreAst.LustreEq(new_cond_ID, ...
                nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.AND, cond_ID, condition));
            s = struct('Name', cond_name, 'LusDatatype', 'bool', 'DataType', 'boolean', ...
                'CompiledType', 'boolean', 'InitialValue', '0', ...
                'ArraySize', '1 1', 'CompiledSize', '1 1', 'Scope', 'Local', ...
                'Port', '1');
            args.data_map(cond_name) = s;
            args.if_cond = new_cond_ID;
            for j=1:length(elif.statements)
                [line, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    elif.statements(j), args);
                code = MatlabUtils.concat(code, line);
            end
            cond_ID = new_cond_ID;
        end
    end
    
    % else
    not_condID = nasa_toLustre.lustreAst.UnaryExpr(...
        nasa_toLustre.lustreAst.UnaryExpr.NOT, cond_ID);
    
    
    if isfield(tree.else_block, 'statements')
        if isstruct(tree.else_block.statements)
            else_block_statements = arrayfun(@(x) x, tree.else_block.statements, 'UniformOutput', 0);
        else
            else_block_statements = tree.else_block.statements;
        end
        args.if_cond = not_condID;
        for i=1:length(else_block_statements)
            [else_block_code, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                else_block_statements{i}, args);
            code = MatlabUtils.concat(code, else_block_code);
        end
        
    end
    
    
    exp_dt = '';
    dim = [];
end

