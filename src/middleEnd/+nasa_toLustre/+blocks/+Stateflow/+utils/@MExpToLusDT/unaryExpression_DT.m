function dt = unaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    %unaryExpression_DT for unaryOperator :  '&' | '*' | '+' | '-' | '~' | '!'
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    if isequal(tree.operator, '~') || isequal(tree.operator, '!')
        dt = 'bool';
    else
        dt = MExpToLusDT.expression_DT(tree.rightExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    end
end

