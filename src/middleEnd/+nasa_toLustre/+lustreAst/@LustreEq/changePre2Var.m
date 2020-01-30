function [new_obj, varIds] = changePre2Var(obj)

    varIds = {};
    [new_lhs, VarIdlhs] = obj.lhs.changePre2Var();
    varIds = [varIds, VarIdlhs];
    
    [new_rhs, VarIdrhs] = obj.rhs.changePre2Var();
    varIds = [varIds, VarIdrhs];
    
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
