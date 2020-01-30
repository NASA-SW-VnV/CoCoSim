function U = setDiff(s1, s2)

    I = ~nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(s1, s2);
    U = s1(I);
end
