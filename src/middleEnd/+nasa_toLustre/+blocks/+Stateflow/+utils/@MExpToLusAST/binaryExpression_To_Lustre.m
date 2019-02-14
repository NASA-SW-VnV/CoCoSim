function [code, exp_dt] = binaryExpression_To_Lustre(BlkObj, tree, parent,...
    blk, data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    tree_type = tree.type;
    
    % get Operands DataType
    exp_dt = MExpToLusDT.binaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    if ismember(tree_type, {'relopGL', 'relopEQ_NE'})
        left_dt = MExpToLusDT.expression_DT(tree.leftExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
        right_dt = MExpToLusDT.expression_DT(tree.rightExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
        operands_dt = MExpToLusDT.upperDT(left_dt, right_dt);
    else
        operands_dt = exp_dt;
    end
    
    % Get Operator
    if isequal(tree_type, 'plus_minus')
        op = tree.operator;
    elseif isequal(tree_type, 'mtimes') ...
            || isequal(tree_type, 'times')
        op = BinaryExpr.MULTIPLY;
    elseif isequal(tree_type, 'mrdivide')...
            || isequal(tree_type, 'rdivide')
        op = BinaryExpr.DIVIDE;
    elseif isequal(tree_type, 'relopGL')
        op = tree.operator;
    elseif isequal(tree_type, 'relopEQ_NE')
        if isequal(tree.operator, '==')
            op = BinaryExpr.EQ;
        else
            op = BinaryExpr.NEQ;
        end
    elseif ismember(tree_type, {'relopAND', 'relopelAND'})
        %TODO relopelAND is bitwise AND
        op = BinaryExpr.AND;
    elseif ismember(tree_type, {'relopOR', 'relopelOR'})
        %TODO relopelOR is bitwise OR
        op = BinaryExpr.OR;
        
    elseif ismember(tree_type, {'mpower', 'power'})
        [code, exp_dt] = getPowerCode(BlkObj, tree, parent, blk, data_map, ...
            inputs, isSimulink, isStateFlow, isMatlabFun);
        return;
    end
    
    % GEt Left Right operand
    left = MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, parent,...
        blk, data_map, inputs, operands_dt, isSimulink, isStateFlow, isMatlabFun);
    right = MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent,...
        blk, data_map, inputs, operands_dt, isSimulink, isStateFlow, isMatlabFun);
    
    % inline operands
    [left, right] = MExpToLusAST.inlineOperands(left, right, tree);
    
    % create code
    code = arrayfun(@(i) BinaryExpr(op, left{i}, right{i}, false), ...
        (1:numel(left)), 'UniformOutput', false);
end

function [code, exp_dt] = getPowerCode(BlkObj, tree, parent, blk, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    exp_dt = 'real';
    tree_type = tree.type;
    BlkObj.addExternal_libraries('LustMathLib_lustrec_math');
    left = MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, parent,...
        blk, data_map, inputs, 'real', isSimulink, isStateFlow, isMatlabFun);
    right = MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent,...
        blk, data_map, inputs, 'real', isSimulink, isStateFlow, isMatlabFun);
    if numel(left) > 1 && isequal(tree_type, 'mpower')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" has a power of matrix is not supported.',...
            tree.text);
        throw(ME);
    end
    if numel(right) == 1
        right = arrayfun(@(x) right{1}, (1:numel(left)), 'UniformOutput', false);
    end
    code = arrayfun(@(i) NodeCallExpr('pow', {left{i},right{i}}), ...
        (1:numel(left)), 'UniformOutput', false);
end