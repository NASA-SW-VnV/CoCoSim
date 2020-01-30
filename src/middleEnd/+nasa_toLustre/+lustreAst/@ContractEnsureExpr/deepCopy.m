function new_obj = deepCopy(obj)

    new_obj = nasa_toLustre.lustreAst.ContractEnsureExpr(obj.id, obj.exp.deepCopy());
end
