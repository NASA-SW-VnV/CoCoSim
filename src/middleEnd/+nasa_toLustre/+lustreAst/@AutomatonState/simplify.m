function new_obj = simplify(obj)

    %% simplify expression

    new_local_vars = cellfun(@(x) x.simplify(), obj.local_vars, 'UniformOutput', 0);

    new_strongTrans = cellfun(@(x) x.simplify(), obj.strongTrans, 'UniformOutput', 0);

    new_weakTrans = cellfun(@(x) x.simplify(), obj.weakTrans, 'UniformOutput', 0);

    new_body = cellfun(@(x) x.simplify(), obj.body, 'UniformOutput', 0);

    new_obj = nasa_toLustre.lustreAst.AutomatonState(obj.name, new_local_vars, ...
        new_strongTrans, new_weakTrans, new_body);
end
