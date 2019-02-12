
function res = recursiveMinMax(op, inputs)
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


