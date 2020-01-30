function exp  = outputsValues(outputsNumber, outputIdx)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    values = arrayfun(@(x) nasa_toLustre.lustreAst.BoolExpr('false'), (1:outputsNumber),...
        'UniformOutput', 0);
    if outputIdx > 0 && outputIdx <= outputsNumber
        values{outputIdx} = nasa_toLustre.lustreAst.BoolExpr('true');
    end
    exp = nasa_toLustre.lustreAst.TupleExpr(values);
end

