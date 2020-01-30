function [new_variables, additionalOutputs, ...
        additionalInputs, inputsMemory] =...
        getForIteratorMemoryVars(variables, node_inputs, memoryIds)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %
    %
    new_variables = {};
    additionalOutputs = {};
    additionalInputs = {};
    inputsMemory = {};
    variables_names = cellfun(@(x) x.getId(), variables, 'UniformOutput', false);
    node_inputs_names = cellfun(@(x) x.getId(), node_inputs, 'UniformOutput', false);
    memoryIds_names = cellfun(@(x) x.getId(), memoryIds, 'UniformOutput', false);
    for i=1:numel(variables_names)
        if ismember(variables_names{i}, memoryIds_names)
            additionalOutputs{end+1} = variables{i};
            additionalInputs{end+1} = nasa_toLustre.lustreAst.LustreVar(strcat('_pre_',...
                variables_names{i}), variables{i}.getDT());
        else
            new_variables{end + 1} = variables{i};
        end
    end
    for i=1:numel(node_inputs_names)
        if ismember(node_inputs_names{i}, memoryIds_names)
            inputsMemory{end+1} = nasa_toLustre.lustreAst.LustreVar(strcat('_pre_',...
                node_inputs_names{i}), node_inputs{i}.getDT());
        end
    end
end

