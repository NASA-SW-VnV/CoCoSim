function [code, exp_dt, dim, extra_code] = if_block_To_Lustre(tree, args)
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
    extra_code = {};
    if_cond = args.if_cond;
    args.expected_lusDT = 'bool';
    [condition, ~, ~, code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
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
        tree_type = tree_statements{i}.type;
        if strcmp(tree_type, 'assignment')
            
            
        end
        [statements_code, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
            tree_statements{i}, args);
        code = MatlabUtils.concat(code, extra_code_i);
        code = MatlabUtils.concat(code, statements_code);
    end
    not_cond_ID = nasa_toLustre.lustreAst.UnaryExpr(...
                nasa_toLustre.lustreAst.UnaryExpr.NOT, cond_ID, false);
    
    
    % elseif
    if ~isempty(tree.elseif_blocks)
        for i=1:length(tree.elseif_blocks)
            elif = tree.elseif_blocks(i);
            cond_name = strcat('ifCond_', num2str(counter), strrep(num2str(rand(1)), '0.', '_'));
            counter = counter + 1;
            new_cond_ID = nasa_toLustre.lustreAst.VarIdExpr(cond_name);
            [condition, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                elif.condition, args);
            code = MatlabUtils.concat(code, extra_code_i);
            code{end+1} = nasa_toLustre.lustreAst.LustreEq(new_cond_ID, ...
                condition);
            
            if_condition = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.AND, not_cond_ID, new_cond_ID);
            
            s = struct('Name', cond_name, 'LusDatatype', 'bool', 'DataType', 'boolean', ...
                'CompiledType', 'boolean', 'InitialValue', '0', ...
                'ArraySize', '1 1', 'CompiledSize', '1 1', 'Scope', 'Local', ...
                'Port', '1');
            args.data_map(cond_name) = s;
            args.if_cond = if_condition;
            for j=1:length(elif.statements)
                [line, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    elif.statements(j), args);
                code = MatlabUtils.concat(code, extra_code_i);
                code = MatlabUtils.concat(code, line);
            end
            not_cond_ID = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.AND, not_cond_ID, ...
                nasa_toLustre.lustreAst.UnaryExpr(...
                nasa_toLustre.lustreAst.UnaryExpr.NOT, new_cond_ID, false), false);
        end
    end
    
    % else
    
    if isfield(tree.else_block, 'statements')
        if isstruct(tree.else_block.statements)
            else_block_statements = arrayfun(@(x) x, tree.else_block.statements, 'UniformOutput', 0);
        else
            else_block_statements = tree.else_block.statements;
        end
        args.if_cond = not_cond_ID;
        for i=1:length(else_block_statements)
            [else_block_code, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                else_block_statements{i}, args);
            code = MatlabUtils.concat(code, extra_code_i);
            code = MatlabUtils.concat(code, else_block_code);
        end
        
    end
    
    
    exp_dt = '';
    dim = [];
end

