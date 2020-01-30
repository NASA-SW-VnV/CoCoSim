function new_obj = simplify(obj)

    new_args = cellfun(@(x) x.simplify(), obj.args, 'UniformOutput', 0);
    % (x) => x
    if numel(new_args) == 1
        new_obj = new_args{1};
    else
        new_obj = nasa_toLustre.lustreAst.TupleExpr(new_args);
    end
end
