
function code = addValue(a, code, outLusDT)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if strcmp(outLusDT, 'int')
        v = IntExpr(int32(a));
    elseif strcmp(outLusDT, 'bool')
        v = BooleanExpr(a);
    else
        v = RealExpr(a);
    end
    code = BinaryExpr(BinaryExpr.ARROW, ...
            v, ...
            UnaryExpr(UnaryExpr.PRE, code));
end


