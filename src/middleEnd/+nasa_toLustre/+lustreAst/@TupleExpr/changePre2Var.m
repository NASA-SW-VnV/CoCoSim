function [new_obj, varIds] = changePre2Var(obj)

    varIds = {};
    new_args = cell(numel(obj.args), 1);
    for i=1:numel(obj.args)
        [new_args{i}, varIds_i] = obj.args{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    
    new_obj = nasa_toLustre.lustreAst.TupleExpr(new_args);
    
end
