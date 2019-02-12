function exp  = outputsValues(outputsNumber, outputIdx)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    values = arrayfun(@(x) BooleanExpr('false'), (1:outputsNumber),...
        'UniformOutput', 0);
    if outputIdx > 0 && outputIdx <= outputsNumber
        values{outputIdx} = BooleanExpr('true');
    end
    exp = TupleExpr(values);
end

