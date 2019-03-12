%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% This function is used for Stateflow
function [call, oututs_Ids] = nodeCall(obj, isInner, InnerValue)
    
    if ~exist('isInner', 'var')
        isInner = false;
    end
    inputs_Ids = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), ...
        obj.inputs, 'UniformOutput', false);
    oututs_Ids = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), ...
        obj.outputs, 'UniformOutput', false);

    for i=1:numel(inputs_Ids)
        if isInner && isequal(inputs_Ids{i}.getId(), ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.isInnerStr())
            inputs_Ids{i} = InnerValue;
        elseif isequal(inputs_Ids{i}.getId(), ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr())
            inputs_Ids{i} = nasa_toLustre.lustreAst.BooleanExpr(true);
        end
    end

    call = nasa_toLustre.lustreAst.NodeCallExpr(obj.name, inputs_Ids);
end
