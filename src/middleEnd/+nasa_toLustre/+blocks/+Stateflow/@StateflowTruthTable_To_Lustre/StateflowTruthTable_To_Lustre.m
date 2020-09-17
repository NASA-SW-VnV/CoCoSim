%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef StateflowTruthTable_To_Lustre
    %StateflowTruthTable_To_Lustre: transform Table to graphical function.
    % Then use StateflowGraphicalFunction_To_Lustre

    
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
                    % TODO: fix Java parser to support conditions with
                    % '\n'. Conditions such as "~(\n..." is not supported.
                    % Current fix: removing '\n' from conditions.
                    c_Conditions = regexprep(c.Condition, '\n', '');
                    if strcmp(c.ConditionValue, 'T')
                        cond{end+1} = sprintf('(%s)', c_Conditions);
                    elseif strcmp(c.ConditionValue, 'F')
                        cond{end+1} = sprintf('~(%s)', c_Conditions);
                    end
                end
                cond_str = coco_nasa_utils.MatlabUtils.strjoin(cond, ' && ');
                actions = {};
                for j = 1 : numel(table.Decisions{i}.Actions)
                    idx = table.Decisions{i}.Actions{j};
                    if isKey(actions_index_map, idx)
                        actions{end+1} = actions_index_map(idx);
                    end
                end
                actions_str = coco_nasa_utils.MatlabUtils.strjoin(actions, '\n');
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

