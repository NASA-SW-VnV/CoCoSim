classdef StateflowGraphicalFunction_To_Lustre
    %StateflowGraphicalFunction_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_code(sfunc)
            global SF_JUNCTIONS_PATH_MAP;
            external_nodes = {};
            external_libraries = {};
            % add junctions
            junctions = sfunc.Junctions;
            for i=1:numel(junctions)
                SF_JUNCTIONS_PATH_MAP(junctions{i}.Path) = junctions{i};
            end
            data_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            inputs = {};
            outputs = {};
            for i=1:numel(sfunc.Data)
                x = sfunc.Data{i};
                data_map(sfunc.Data{i}.Name) = x;
                if isequal(x.Scope, 'Input')
                    inputs{end+1} = LustreVar(x.Name, x.LusDatatype);
                elseif isequal(x.Scope, 'Output')
                    outputs{end+1} = LustreVar(x.Name, x.LusDatatype);
                end
            end
            % Go over Junctions Outertransitions: condition/Transition Actions
            for i=1:numel(junctions)
                try
                    [external_nodes_i, external_libraries_i ] = ...
                        StateflowJunction_To_Lustre.write_code(junctions{i}, data_map);
                    external_nodes = [external_nodes, external_nodes_i];
                    external_libraries = [external_libraries, external_libraries_i];
                catch me
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'SF_To_LustreNode', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, 'SF_To_LustreNode', '');
                    end
                    display_msg(sprintf('Translation of Junction %s failed', ...
                        junctions{i}.Origin_path),...
                        MsgType.ERROR, 'SF_To_LustreNode', '');
                end
            end
            
            % create main node
            parentPath = sfunc.Path;
            T = sfunc.Composition.DefaultTransitions;
            isDefaultTrans = true;
            % Default transitions actions
            [transition_nodes_j, external_libraries_j ] = ...
                StateflowTransition_To_Lustre.get_Actions(T{1}, data_map, sfunc, ...
                isDefaultTrans);
            external_nodes = [external_nodes, transition_nodes_j];
            external_libraries = [external_libraries, external_libraries_j];
            
            
            node_name = SF_To_LustreNode.getUniqueName(sfunc);
            comment = LustreComment(...
                sprintf('Stateflow Graphical Function %s', sfunc.Origin_path), true);
            [main_node, external_libraries_i] = ...
                StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, ...
                parentPath, ...
                isDefaultTrans, ...
                node_name, comment);
            external_libraries = [external_libraries, external_libraries_i];
            main_node.setInputs(inputs);
            % check if number of outputs is the same
            if numel(outputs) ~= numel(main_node.getOutputs())
                display_msg(...
                    sprintf(['Stateflow Function %s has %d outputs.'...
                    ' But %d variable has been changed in Condition Actions inside the Function.'], ...
                    sfunc.Path, numel(outputs), numel(main_node.getOutputs())), ...
                    MsgType.ERROR, 'StateflowGraphicalFunction_To_Lustre', '');
            end
        end
        
        function options = getUnsupportedOptions(sfunc, varargin)
            options = {};
            data = sfunc.Data;
            isOutput = cellfun(@(x) strcmp(x.Scope, 'Output'), data);
            outputs = data(isOutput);
            if isempty(outputs)
                options{end+1} = sprintf(['Stateflow Function %s has no outputs.'...
                    ' CoCoSim does not support SFunctions with no outputs or that use chart data directly.'], ...
                    sfunc.Path);
            end
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

