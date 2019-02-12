function dt = parenthesedExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    dt = MExpToLusDT.expression_DT(tree.expression, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
end

