function [new_obj, varIds] = changePre2Var(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.BinaryExpr
    varIds = {};
    [leftExp, varIdLeft] = obj.left.changePre2Var();
    varIds = [varIds, varIdLeft];
    [rightExp, varIdright] = obj.right.changePre2Var();
    varIds = [varIds, varIdright];
    new_obj = BinaryExpr(obj.op,...
        leftExp,...
        rightExp, ...
        obj.withPar, obj.addEpsilon, obj.epsilon);
end
