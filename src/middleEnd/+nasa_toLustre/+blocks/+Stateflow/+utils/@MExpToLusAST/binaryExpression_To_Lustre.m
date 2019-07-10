function [code, exp_dt, dim] = binaryExpression_To_Lustre(BlkObj, tree, parent,...
        blk, data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    tree_type = tree.type;
    dim = [];
    % get Operands DataType
    exp_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.binaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    if ismember(tree_type, {'relopGL', 'relopEQ_NE'})
        left_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.leftExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
        right_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.rightExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
        operands_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.upperDT(left_dt, right_dt);
    else
        operands_dt = exp_dt;
    end
    
    % GEt Left Right operand
    [left, ~, left_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, parent,...
        blk, data_map, inputs, operands_dt, isSimulink, isStateFlow, isMatlabFun);
    [right, ~, right_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent,...
        blk, data_map, inputs, operands_dt, isSimulink, isStateFlow, isMatlabFun);
    
    % Get Operator
    if strcmp(tree_type, 'plus_minus') % '+' '-'
        dim = left_dim;
        op = tree.operator;
    elseif strcmp(tree_type, 'mtimes') % '*'
        [code, dim] = nasa_toLustre.blocks.Stateflow.utils.MF2LusUtils.mtimesFun_To_Lustre(left, left_dim, right, right_dim);
        return;
    elseif strcmp(tree_type, 'times') % '.*'
        if length(left_dim) == 1 && left_dim(1) == 1
            dim = right_dim;
        elseif length(right_dim) == 1 && right_dim(1) == 1
            dim = left_dim;
        else
            %TODO support more than 3 dimensions
            dim = left_dim;
        end
        op = nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY;
    elseif strcmp(tree_type, 'mrdivide')... % '/' './'
            || strcmp(tree_type, 'rdivide')
        if length(left_dim) == 1 && left_dim(1) == 1
            dim = right_dim;
        elseif length(right_dim) == 1 && right_dim(1) == 1
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
        if length(left_dim) == 1 && left_dim(1) == 1
            dim = right_dim;
        else
            dim = left_dim;
        end
        op = tree.operator;
    elseif strcmp(tree_type, 'relopEQ_NE') % '==' '~='
        if length(left_dim) == 1 && left_dim(1) == 1
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
        if length(left_dim) == 1 && left_dim(1) == 1
            dim = right_dim;
        else
            dim = left_dim;
        end
        %TODO relopelAND is bitwise AND
        op = nasa_toLustre.lustreAst.BinaryExpr.AND;
    elseif ismember(tree_type, {'relopOR', 'relopelOR'}) % '||' '|'
        if length(left_dim) == 1 && left_dim(1) == 1
            dim = right_dim;
        else
            dim = left_dim;
        end
        %TODO relopelOR is bitwise OR
        op = nasa_toLustre.lustreAst.BinaryExpr.OR;
        
    elseif ismember(tree_type, {'mpower', 'power'}) % '^' '.^'
        [code, exp_dt, dim] = getPowerCode(BlkObj, tree, parent, blk, data_map, ...
            inputs, isSimulink, isStateFlow, isMatlabFun);
        return;
    end
    
    % inline operands
    [left, right] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.inlineOperands(left, right, tree);
    
    % create code
    code = arrayfun(@(i) nasa_toLustre.lustreAst.BinaryExpr(op, left{i}, right{i}, false), ...
        (1:numel(left)), 'UniformOutput', false);
end

function [code, exp_dt, dim] = getPowerCode(BlkObj, tree, parent, blk, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    
    exp_dt = 'real';
    tree_type = tree.type;
    BlkObj.addExternal_libraries('LustMathLib_lustrec_math');
    [left, ~, left_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, parent,...
        blk, data_map, inputs, 'real', isSimulink, isStateFlow, isMatlabFun);
    [right, ~, right_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent,...
        blk, data_map, inputs, 'real', isSimulink, isStateFlow, isMatlabFun);
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
