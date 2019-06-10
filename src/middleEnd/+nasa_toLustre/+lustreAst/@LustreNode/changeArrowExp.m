%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_obj = changeArrowExp(obj, cond)
    new_bodyEqs = cellfun(@(x) x.changeArrowExp(cond), obj.bodyEqs, 'UniformOutput', 0);

    new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name,...
        obj.inputs, ...
        obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
        obj.isMain, obj.isImported);
end
