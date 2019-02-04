function dt = transpose_DT(tree, data_map, inputs, isSimulink, isStateFlow)
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    dt = MExpToLusDT.expression_DT(tree.leftExp, data_map, inputs, isSimulink, isStateFlow);
end

