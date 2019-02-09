
function code = getExpofNDelays(x0, u, d)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if d == 0
        code = u;
        %sprintf(' %s ' , u);
    else
        code = BinaryExpr(BinaryExpr.ARROW, ...
            x0, ...
            UnaryExpr(UnaryExpr.PRE, ...
                Delay_To_Lustre.getExpofNDelays(x0, u, d - 1)));
        %sprintf(' %s -> pre(%s) ', x0 , Delay_To_Lustre.getExpofNDelays(x0, u, D -1));
    end

end

