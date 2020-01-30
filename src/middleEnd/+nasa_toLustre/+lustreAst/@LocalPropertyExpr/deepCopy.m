function new_obj = deepCopy(obj)

    new_obj = nasa_toLustre.lustreAst.LocalPropertyExpr(obj.id, ...
        obj.exp.deepCopy());
end
