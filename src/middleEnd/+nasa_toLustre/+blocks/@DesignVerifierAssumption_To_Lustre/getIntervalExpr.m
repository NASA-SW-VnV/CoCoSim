
function exp = getIntervalExpr(x, xDT, interval)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if interval.lowIncluded
        op1 = BinaryExpr.LTE;
    else
        op1 = BinaryExpr.LT;
    end
    if interval.highIncluded
        op2 = BinaryExpr.LTE;
    else
        op2 = BinaryExpr.LT;
    end
    if strcmp(xDT, 'int')
        vLow = IntExpr(interval.low);
        vHigh = IntExpr(interval.high);
    elseif strcmp(xDT, 'bool')
        vLow = BooleanExpr(interval.low);
        vHigh = BooleanExpr(interval.high);
    else
        vLow = RealExpr(interval.low);
        vHigh = RealExpr(interval.high);
    end
    exp = BinaryExpr(BinaryExpr.AND, ...
        BinaryExpr(op1, vLow, x), ...
        BinaryExpr(op2, x, vHigh));
end
