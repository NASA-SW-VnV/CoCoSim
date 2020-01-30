classdef StateflowTruthTable_To_Lustre
    %StateflowTruthTable_To_Lustre: transform Table to graphical function.
    % Then use StateflowGraphicalFunction_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        
        function  [main_node, external_nodes, external_libraries ] = ...
                write_code(table, chart_data, varargin)
            
            %% create Junctions
            tablePath = table.Path;
            INIT_action = '';
            FINAL_action = '';
            actions_index_map = containers.Map('KeyType', 'int32', 'ValueType', 'char');
            for i = 1 : numel(table.Actions)
                if isfield(table.Actions{i}, 'Label')
                    if strcmp(table.Actions{i}.Label, 'INIT')
                        INIT_action = table.Actions{i}.Action;
                    elseif strcmp(table.Actions{i}.Label, 'FINAL')
                        FINAL_action = table.Actions{i}.Action;
                    end
                end
                actions_index_map(table.Actions{i}.Index) = table.Actions{i}.Action;
            end
            
            finalJunction = ...
                nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildJunctionStruct(tablePath);
            finalJunction.OuterTransitions = {};
            beforeFinalJunction = ...
                nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildJunctionStruct(tablePath);
            beforeFinalJunction.OuterTransitions{1} = nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildTransitionStruct(1, ...
                finalJunction, '', FINAL_action, beforeFinalJunction.Path);
            
            junctions = {};
            for i = 1 : numel(table.Decisions)
                cond = {};
                for j = 1 : numel(table.Decisions{i}.Conditions)
                    c = table.Decisions{i}.Conditions{j};
                    if strcmp(c.ConditionValue, 'T')
                        cond{end+1} = sprintf('(%s)', c.Condition);
                    elseif strcmp(c.ConditionValue, 'F')
                        cond{end+1} = sprintf('~(%s)', c.Condition);
                    end
                end
                cond_str = MatlabUtils.strjoin(cond, ' && ');
                actions = {};
                for j = 1 : numel(table.Decisions{i}.Actions)
                    idx = table.Decisions{i}.Actions{j};
                    if isKey(actions_index_map, idx)
                        actions{end+1} = actions_index_map(idx);
                    end
                end
                actions_str = MatlabUtils.strjoin(actions, '\n');
                junc =  nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildJunctionStruct(tablePath);
                junc.OuterTransitions{1} = nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildTransitionStruct(1, ...
                    beforeFinalJunction, cond_str, actions_str, junc.Path);
                junctions{i} = junc;
            end
            % connect between junctions
            for i=1:numel(junctions)-1
                junctions{i}.OuterTransitions{2} = nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildTransitionStruct(2, ...
                    junctions{i + 1}, '', '', junctions{i}.Path);
            end
            junctions{end+1} = beforeFinalJunction;
            junctions{end+1} = finalJunction;
            %% create graphical function object
            functionStruct.Path = table.Path;
            functionStruct.Origin_path = table.Origin_path;
            functionStruct.Id = table.Id;
            functionStruct.Name = table.Name;
            functionStruct.LabelString = table.LabelString;
            functionStruct.Data =  table.Data;
            functionStruct.Events = {};
            
            
            
            functionStruct.Junctions = junctions;
            % SubJunctions: Name and Type (CONNECTIVE)
            functionStruct.Composition.SubJunctions = cell(length(junctions), 1);
            for i = 1 : length(junctions)
                jun.Name = junctions{i}.Type;
                jun.Type = junctions{i}.Type;
                functionStruct.Composition.SubJunctions{i} = jun;
            end
            % Create the composition
            functionStruct.Composition.Type = 'EXCLUSIVE_OR';
            functionStruct.Composition.Substates = {};
            functionStruct.Composition.States = {};
            
            
            functionStruct.Composition.DefaultTransitions{1} = ...
                nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.buildTransitionStruct(1, ...
                functionStruct.Junctions{1}, '', INIT_action, '');
%             try
%                 % apply the same IR pre-processing to this structure
%                 chart.GraphicalFunctions{1} = functionStruct;
%                 [new_chart, ~] = nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_IR_pp(chart, false);
%                 functionStruct = new_chart.GraphicalFunctions{1};
%             catch
%             end
            [main_node, external_nodes, external_libraries ] = ...
                nasa_toLustre.blocks.Stateflow.StateflowGraphicalFunction_To_Lustre.write_code(functionStruct, chart_data);
        end
        
        function options = getUnsupportedOptions(table, varargin)
            if isfield(table, 'Language') && strcmp(table.Language, 'C')
                obj.addUnsupported_options(...
                    sprintf(['Action Language "C" for TrthTable %s is not supported. You need to set Action Language to "Matlab".'],....
                    table.Path));
            end
            options = {};
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %%
        id_out = incrementID()

        junc = buildJunctionStruct(tablePath)

        transitionStruct = buildTransitionStruct(ExecutionOrder, destination, C, CAction, srcPath)

    end
    
end

