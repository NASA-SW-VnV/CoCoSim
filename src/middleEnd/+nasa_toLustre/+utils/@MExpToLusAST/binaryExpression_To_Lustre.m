function [code, exp_dt, dim, extra_code] = binaryExpression_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    tree_type = tree.type;
    dim = [];
    extra_code = {};
    % get Operands DataType
    exp_dt = nasa_toLustre.utils.MExpToLusDT.binaryExpression_DT(tree, args);
    if ismember(tree_type, {'relopGL', 'relopEQ_NE'})
        left_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.leftExp, args);
        right_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.rightExp, args);
        operands_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(left_dt, right_dt);
    else
        operands_dt = exp_dt;
    end
    
    % GEt Left Right operand
    args.expected_lusDT = operands_dt;
    [left, ~, left_dim, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.leftExp, args);
    [right, ~, right_dim, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.rightExp, args);
    extra_code = MatlabUtils.concat(left_extra_code, right_extra_code);

    % Get Operator
    if strcmp(tree_type, 'plus_minus') % '+' '-'
        dim = left_dim;
        op = tree.operator;
    elseif strcmp(tree_type, 'mtimes') % '*'
        [code, dim] = nasa_toLustre.utils.MF2LusUtils.mtimesFun_To_Lustre(left, left_dim, right, right_dim);
        return;
    elseif strcmp(tree_type, 'times') % '.*'
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
            %TODO support more than 3 dimensions
        end
        op = nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY;
    elseif strcmp(tree_type, 'mrdivide')... % '/' './'
            || strcmp(tree_type, 'rdivide')
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        elseif isempty(right_dim) || (length(right_dim) >= 1 && prod(right_dim) == 1)
            dim = left_dim;
        elseif length(left_dim) <= 2 && length(right_dim) <= 2
            if strcmp(tree_type, 'mrdivide')
                dim = [left_dim(1), right_dim(1)];
            else
                dim = left_dim;
            end
        else
            %TODO support more than 3 dimensions
            dim = left_dim;
        end
        op = nasa_toLustre.lustreAst.BinaryExpr.DIVIDE;
    elseif strcmp(tree_type, 'relopGL') % '<' '>' '<=' '>='
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        op = tree.operator;
    elseif strcmp(tree_type, 'relopEQ_NE') % '==' '~='
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        if strcmp(tree.operator, '==')
            op = nasa_toLustre.lustreAst.BinaryExpr.EQ;
        else
            op = nasa_toLustre.lustreAst.BinaryExpr.NEQ;
        end
    elseif ismember(tree_type, {'relopAND', 'relopelAND'}) % '&&' '&'
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        %TODO relopelAND is bitwise AND
        op = nasa_toLustre.lustreAst.BinaryExpr.AND;
    elseif ismember(tree_type, {'relopOR', 'relopelOR'}) % '||' '|'
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        %TODO relopelOR is bitwise OR
        op = nasa_toLustre.lustreAst.BinaryExpr.OR;
        
    elseif ismember(tree_type, {'mpower', 'power'}) % '^' '.^'
        [code, exp_dt, dim, extra_code] = getPowerCode(tree, args);
        return;
    end
    
    % inline operands
    [left, right] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(left, right, tree);
    
    % create code
    code = arrayfun(@(i) nasa_toLustre.lustreAst.BinaryExpr(op, left{i}, right{i}, false), ...
        (1:numel(left)), 'UniformOutput', false);
end

function [code, exp_dt, dim, extra_code] = getPowerCode(tree, args)
    
    exp_dt = 'real';
    tree_type = tree.type;
    args.blkObj.addExternal_libraries('LustMathLib_lustrec_math');
    args.expected_lusDT = 'real';
    [left, ~, left_dim, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.leftExp, args);
    [right, ~, right_dim, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.rightExp, args);
    extra_code = MatlabUtils.concat(left_extra_code, right_extra_code);
    if numel(left) > 1 && strcmp(tree_type, 'mpower')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" has a power of matrix is not supported.',...
            tree.text);
        throw(ME);
    end
    if numel(right) == 1
        dim = left_dim;
        right = arrayfun(@(x) right{1}, (1:numel(left)), 'UniformOutput', false);
    else
        dim = right_dim;
    end
    code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr('pow', {left{i},right{i}}), ...
        (1:numel(left)), 'UniformOutput', false);
end
