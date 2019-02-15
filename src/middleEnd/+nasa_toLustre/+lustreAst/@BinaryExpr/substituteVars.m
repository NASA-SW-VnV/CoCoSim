function new_obj = substituteVars(obj, oldVar, newVar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.BinaryExpr
    new_obj = BinaryExpr(obj.op,...
        obj.left.substituteVars( oldVar, newVar),...
        obj.right.substituteVars( oldVar, newVar), ...
        obj.withPar, obj.addEpsilon, obj.epsilon);
end
