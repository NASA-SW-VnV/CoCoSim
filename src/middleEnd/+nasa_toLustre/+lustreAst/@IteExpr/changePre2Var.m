function [new_obj, varIds] = changePre2Var(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
    [cond, vcondId] = obj.condition.changePre2Var();
    [then, thenCondId] = obj.thenExpr.changePre2Var();
    [elseE, elseCondId] = obj.ElseExpr.changePre2Var();
    varIds = [vcondId, thenCondId, elseCondId];
    new_obj = nasa_toLustre.lustreAst.IteExpr(cond, then, elseE, obj.OneLine);
end
