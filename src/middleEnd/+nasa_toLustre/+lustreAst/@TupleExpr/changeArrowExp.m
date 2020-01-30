function new_obj = changeArrowExp(obj, cond)

    new_args = cellfun(@(x) x.changeArrowExp(cond), obj.args, 'UniformOutput', 0);
    
    new_obj = nasa_toLustre.lustreAst.TupleExpr(new_args);
end
