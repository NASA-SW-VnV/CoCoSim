%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [new_obj, varIds] = pseudoCode2Lustre(obj, data_map)
        varIds = {};
    outputs_map = containers.Map('KeyType', 'char', 'ValueType', 'int32');

    %initialize outputs_map
    for i=1:numel(obj.outputs)
        outputs_map(obj.outputs{i}.getId()) = 0;
    end
    for i=1:numel(obj.localVars)
        outputs_map(obj.localVars{i}.getId()) = 0;
    end
    % go over body equations to change each occurance of outputs to new var
    new_bodyEqs = cell(numel(obj.bodyEqs),1);
    isLeft = false;
    I = [];
    for i=1:numel(obj.bodyEqs)
        if ~isa(obj.bodyEqs{i}, 'nasa_toLustre.lustreAst.LustreEq') ...
                && ~isa(obj.bodyEqs{i}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
            %Keep Assertions, localProperties till the end to use
            %the last occurance.
            I = [I i];
            continue;
        end
        [new_bodyEqs{i}, outputs_map] = ...
            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft, obj, data_map);
    end

    %Go over Assertions, localProperties, ...
    for i=I
        [new_bodyEqs{i}, outputs_map] = ...
            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft, obj, data_map);
    end
    if ~isempty(obj.localContract)
        new_localContract = obj.localContract.pseudoCode2Lustre(outputs_map, isLeft, obj, data_map);
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
                nasa_toLustre.lustreAst.LustreVar(strcat(out_name, '__', num2str(j)),...
                out_DT));
        end
        if last_Idx > 0
            obj.outputs{i} = ...
                nasa_toLustre.lustreAst.LustreVar(strcat(out_name, '__', num2str(last_Idx)),...
                out_DT);
        end
    end
    tobeRemoved = {};
    for i=1:numel(obj.localVars)
        out_name = obj.localVars{i}.getId();
        out_DT = obj.localVars{i}.getDT();
        if ~isKey(outputs_map, out_name)
            continue;
        end
        last_Idx = outputs_map(out_name);
        if last_Idx >= 1
            tobeRemoved{end+1} = obj.localVars{i};
        end
        for j=1:last_Idx
            obj.addVar(...
                nasa_toLustre.lustreAst.LustreVar(strcat(out_name, '__', num2str(j)),...
                out_DT));
        end
        
    end
    for i=1:length(tobeRemoved)
        obj.localVars =...
               nasa_toLustre.lustreAst.LustreVar.removeVar(obj.localVars, tobeRemoved{i});
    end
    % construct the node
    new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
        obj.outputs, new_localContract, obj.localVars, new_bodyEqs, ...
        obj.isMain, obj.isImported);
end
