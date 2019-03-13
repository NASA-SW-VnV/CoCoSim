function [new_obj, varIds] = changePre2Var(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    varIds = {};
    [new_lhs, VarIdlhs] = obj.lhs.changePre2Var();
    varIds = [varIds, VarIdlhs];
    
    [new_rhs, VarIdrhs] = obj.rhs.changePre2Var();
    varIds = [varIds, VarIdrhs];
    
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
