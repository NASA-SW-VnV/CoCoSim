%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function is used in Stateflow compiler to change from imperative
% code to Lustre
function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
    [new_exp, outputs_map] = obj.exp.pseudoCode2Lustre(outputs_map, isLeft);
    new_obj = nasa_toLustre.lustreAst.AssertExpr(new_exp);
end
