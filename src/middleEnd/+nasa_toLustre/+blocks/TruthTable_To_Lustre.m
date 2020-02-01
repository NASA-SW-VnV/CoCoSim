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
classdef TruthTable_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % TruthTable_To_Lustre
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, main_sampletime, varargin)
            
            
            % Create a Stateflow Chart from the TruthTable and use Stateflow to Lustre
            % translator
            stateflowRoot = sfroot;
            % get the model object
            model = stateflowRoot.find('-isa', 'Simulink.BlockDiagram', 'Name',bdroot(blk.Origin_path));
            % get the chart object
            T = model.find('-isa','Stateflow.TruthTable', 'Path', blk.Origin_path);
            chart_struct = blk;
            chart_struct.StateflowContent = nasa_toLustre.blocks.TruthTable_To_Lustre.chart_struct(T);
            chart_struct.StateflowContent = nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_IR_pp(chart_struct.StateflowContent);
            [main_node, external_nodes, external_libraries ] = nasa_toLustre.frontEnd.SF_To_LustreNode.chart2node(parent,  chart_struct, main_sampletime, lus_backend, xml_trace);
            obj.addExtenal_node(external_nodes);
            obj.addExtenal_node(main_node);
            obj.addExternal_libraries(external_libraries);
            
            % Make the call
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampletime);
            obj.addVariable(outputs_dt);
            [inputs, ~] = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            if length(inputs) > 1
                inputs = MatlabUtils.concat(inputs) ;
            end
            codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs,...
                nasa_toLustre.lustreAst.NodeCallExpr(main_node.getName(), inputs));
            obj.addCode( codes );
            
            
            
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    methods(Static)
        function [StateflowContentStruct] = chart_struct(T)
            
            javaaddpath(which('ChartParser.jar'));
            chart = T.chart;
            
            StateflowContentStruct = {};
            % get the name of the chart block
            StateflowContentStruct.Name = chart.Name;

            
            %get the chart ActionLanguage, StateMachineType, ChartUpdate,
            % ExecuteAtInitialization, InitializeOutput, EnableNonTerminalStates
            StateflowContentStruct.ActionLanguage = T.Language;
            StateflowContentStruct.StateMachineType = 'Classic';
            StateflowContentStruct.ChartUpdate = chart.ChartUpdate;
            StateflowContentStruct.ExecuteAtInitialization = false;
            StateflowContentStruct.InitializeOutput = false;
            StateflowContentStruct.EnableNonTerminalStates = false;
            
            %get the chart path
            StateflowContentStruct.Path = chart.Path;
            
            % get the data of the chart
            chartData = chart.find('-isa','Stateflow.Data', '-depth', 1);
            % build the json struct for data
            StateflowContentStruct.Data = cell(length(chartData),1);
            for index = 1 : length(chartData)
                StateflowContentStruct.Data{index} = SFStruct.buildDataStruct(chartData(index));
            end
            
            
            % get the events of the chart
            chartEvents = chart.find('-isa','Stateflow.Event');
            % build the json struct for events
            StateflowContentStruct.Events = cell(length(chartEvents),1);
            for index = 1 : length(chartEvents)
                StateflowContentStruct.Events{index} = SFStruct.buildEventStruct(chartEvents(index));
            end
            
            % add a virtual state that represents the chart itself
            % set the state path
            virtualState.Path = chart.path;
            virtualState.Name = chart.Name;
            %set the id of the state
            virtualState.Id = chart.id;
            virtualState.InnerTransitions = {};
            virtualState.OuterTransitions = {};
            states_fields = {'Entry', 'During', 'Exit', 'Bind', 'On', 'OnAfter', ...
                'OnBefore', 'OnAt', 'OnEvery'};
            for f=states_fields
                virtualState.Actions.(f{1}) = '';
            end
            virtualState.Composition.Type = 'EXCLUSIVE_OR';
            virtualState.Composition.DefaultTransitions = {};
            virtualState.Composition.Substates{1} = 'A';
            virtualState.Composition.States{1} = 1;
            virtualState.Composition.SubJunctions = {};
            StateflowContentStruct.States{1} = virtualState;
            
            % Add the state that will call TruthTable
            stateA.Path = fullfile(virtualState.Path, 'A');
            stateA.Name = 'A';
            stateA.Id = 1;
            stateA.InnerTransitions = {};
            stateA.OuterTransitions = {};
            states_fields = {'Exit', 'Bind', 'On', 'OnAfter', ...
                'OnBefore', 'OnAt', 'OnEvery'};
            for f=states_fields
                stateA.Actions.(f{1}) = '';
            end
            stateA.Actions.Entry = sprintf('%s();', T.Name);
            stateA.Actions.During = sprintf('%s();', T.Name);
            stateA.Composition.Type = 'EXCLUSIVE_OR';
            stateA.Composition.DefaultTransitions = {};
            stateA.Composition.Substates = {};
            stateA.Composition.States = {};
            stateA.Composition.SubJunctions = {};
            StateflowContentStruct.States{2} = stateA;
            %
            
            StateflowContentStruct.Junctions = {};
            StateflowContentStruct.GraphicalFunctions = {};
            StateflowContentStruct.SimulinkFunctions = {};
            
            %get the truth tables in the chart
            chartTruthTables = chart.find('-isa','Stateflow.TruthTable');
            % build the json struct for truth tables
            StateflowContentStruct.TruthTables = cell(length(chartTruthTables),1);
            for index = 1 : length(chartTruthTables)
                StateflowContentStruct.TruthTables{index} = SFStruct.buildTruthTableStruct(chartTruthTables(index));
            end
        end
    end
end

