function exp  = outputsValues(outputsNumber, outputIdx)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    values = arrayfun(@(x) nasa_toLustre.lustreAst.BooleanExpr('false'), (1:outputsNumber),...
        'UniformOutput', 0);
    if outputIdx > 0 && outputIdx <= outputsNumber
        values{outputIdx} = nasa_toLustre.lustreAst.BooleanExpr('true');
    end
    exp = nasa_toLustre.lustreAst.TupleExpr(values);
end

