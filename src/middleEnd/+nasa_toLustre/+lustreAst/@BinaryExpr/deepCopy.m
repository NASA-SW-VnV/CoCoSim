function new_obj = deepCopy(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    new_obj = nasa_toLustre.lustreAst.BinaryExpr(obj.op,...
        obj.left.deepCopy(),...
        obj.right.deepCopy(), ...
        obj.withPar, obj.addEpsilon, obj.epsilon);
end
