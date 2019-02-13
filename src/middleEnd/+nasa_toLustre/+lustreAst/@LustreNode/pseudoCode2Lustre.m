%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [new_obj, varIds] = pseudoCode2Lustre(obj)
    import nasa_toLustre.lustreAst.*
    varIds = {};
    outputs_map = containers.Map('KeyType', 'char', 'ValueType', 'int32');

    %initialize outputs_map
    for i=1:numel(obj.outputs)
        outputs_map(obj.outputs{i}.getId()) = 0;
    end

    % go over body equations to change each occurance of outputs to new var
    new_bodyEqs = cell(numel(obj.bodyEqs),1);
    isLeft = false;
    I = [];
    for i=1:numel(obj.bodyEqs)
        if ~isa(obj.bodyEqs{i}, 'LustreEq') ...
                && ~isa(obj.bodyEqs{i}, 'ConcurrentAssignments')
            %Keep Assertions, localProperties till the end to use
            %the last occurance.
            I = [I i];
            continue;
        end
        [new_bodyEqs{i}, outputs_map] = ...
            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft);
    end

    %Go over Assertions, localProperties, ...
    for i=I
        [new_bodyEqs{i}, outputs_map] = ...
            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft);
    end
    if ~isempty(obj.localContract)
        new_localContract = obj.localContract.pseudoCode2Lustre(outputs_map, isLeft);
    else
        new_localContract = obj.localContract;
    end
    %add the new vars and change outputs names to the last occurance
    for i=1:numel(obj.outputs)
        out_name = obj.outputs{i}.getId();
        out_DT = obj.outputs{i}.getDT();
        last_Idx = outputs_map(out_name);
        for j=1:last_Idx-1
            obj.addVar(...
                LustreVar(strcat(out_name, '__', num2str(j)),...
                out_DT));
        end
        if last_Idx > 0
            obj.outputs{i} = ...
                LustreVar(strcat(out_name, '__', num2str(last_Idx)),...
                out_DT);
        end
    end
    new_obj = LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
        obj.outputs, new_localContract, obj.localVars, new_bodyEqs, ...
        obj.isMain, obj.isImported);
end
