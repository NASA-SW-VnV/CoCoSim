function res = recursiveMinMax(op, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    n = numel(inputs);
    if n == 1
        res = inputs{1};
    elseif n == 2
        res = NodeCallExpr(op, {inputs{1}, inputs{2}});
    else
        res = NodeCallExpr(op, ...
            {inputs{1}, ...
            MinMax_To_Lustre.recursiveMinMax(op,  inputs(2:end))});
    end
end


