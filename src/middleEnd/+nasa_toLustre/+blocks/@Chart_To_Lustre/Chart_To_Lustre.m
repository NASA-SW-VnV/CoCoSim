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
classdef Chart_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Chart_To_Lustre translates Stateflow chart to Lustre.
    % This version is temporal using the old compiler. New version using
    % lustref compiler is comming soon.
    

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            
            %% add Chart Node
            [main_node, external_nodes, external_libraries_i] = ...
                nasa_toLustre.blocks.Chart_To_Lustre.getChartNodes(parent, blk, main_sampleTime, lus_backend, coco_backend, xml_trace);
            obj.addExtenal_node(main_node);
            obj.addExtenal_node(external_nodes);
            obj.addExternal_libraries(external_libraries_i);
            %% add Chart call
            try
                TOLUSTRE_SF_COMPILER = evalin('base', 'TOLUSTRE_SF_COMPILER');
            catch
                TOLUSTRE_SF_COMPILER =2;
            end
            if TOLUSTRE_SF_COMPILER == 1
                % if using old lustre compiler for Stateflow. Uncomment this
                node_name = get_full_name( blk, true );
            else
                % the new compiler
                node_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            end
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            [triggerInputs] =nasa_toLustre.utils.SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            codes = {};
            if ~isempty(triggerInputs)
                cond = cell(1, blk.CompiledPortWidths.Trigger);
                for i=1:blk.CompiledPortWidths.Trigger
                    TriggerType = blk.StateflowContent.Events{i}.Trigger;
                    [lusTriggerportDataType, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Trigger{1});
                    [triggerCode, status] =nasa_toLustre.utils.SLX2LusUtils.getResetCode(...
                        TriggerType, lusTriggerportDataType, triggerInputs{i} , zero);
                    if status
                        display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                            TriggerType, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                            MsgType.ERROR, 'Constant_To_Lustre', '');
                        return;
                    end
                    v_name = sprintf('%s_Event%d', node_name, i);
                    obj.addVariable(nasa_toLustre.lustreAst.LustreVar(v_name, 'bool'));
                    codes{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(v_name), triggerCode);
                    cond{i} = nasa_toLustre.lustreAst.VarIdExpr(v_name);
                end
                inputs = [cond, inputs];
            end
            if isempty(inputs)
                inputs{1} = nasa_toLustre.lustreAst.BoolExpr(true);
            end
            
            
            codes{end+1} = nasa_toLustre.lustreAst.LustreEq(outputs, nasa_toLustre.lustreAst.NodeCallExpr(node_name, inputs));
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            
            [triggerInputs] =nasa_toLustre.utils.SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            SFContent = blk.StateflowContent;
            %% Check chart properties
            %Action language for programming the chart. Can be C or MATLAB.
            if strcmp(SFContent.ActionLanguage, 'C')
                obj.addUnsupported_options(...
                    sprintf(['Action Language "C" for chart %s is not supported. You need to set Action Language to "Matlab".'...
                    '\nYou can change the action language by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %Type of state machine to create. Default is Classic,
            %which provides the full set of semantics for MATLAB charts
            %and C charts. You can also create Mealy and Moore charts,
            %which use a subset of Stateflow chart semantics
            if strcmp(SFContent.StateMachineType, 'Moore')
                obj.addUnsupported_options(...
                    sprintf(['State MachineType "Moore" for chart %s is not supported. You need to use different State MachineType.'...
                    '\nYou can change the State MachineType by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %Activation method of this chart. Can be 'INHERITED' (default),
            %'DISCRETE', or 'CONTINUOUS'.
            if strcmp(SFContent.ChartUpdate, 'CONTINUOUS')
                obj.addUnsupported_options(...
                    sprintf(['Update Method "CONTINUOUS" for chart %s is not supported. You need to use different Discrete Update Method.'...
                    '\nYou can change the Update Method by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %If set to true (default = false),
            %this chart's state configuration is initialized at time zero
            %instead of at the first input event.
            if SFContent.ExecuteAtInitialization && ~isempty(triggerInputs)
                obj.addUnsupported_options(...
                    sprintf(['Execute (enter) Chart At Initialization for chart %s is not supported. You need to deactivate it.'...
                    '\nYou can change the property by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %Applies the initial value of outputs every time a chart wakes up, not only at time 0
            if SFContent.InitializeOutput
                obj.addUnsupported_options(...
                    sprintf(['Applies the initial value of outputs every time a chart wakes up, for chart %s is not supported. You need to deactivate it.'...
                    '\nYou can change the property by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %If set to true (default = false), enables super step semantics for the chart
            if SFContent.EnableNonTerminalStates
                obj.addUnsupported_options(...
                    sprintf(['Super Step semantics for the chart %s is not supported. You need to deactivate it.'...
                    '\nYou can change the property by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %% add unsupported features
            
            if ~isempty(SFContent.SimulinkFunctions)
                obj.addUnsupported_options(...
                    sprintf('Simulink Functions in chart %s are not supported. Work in progress!' ,....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %% add unsupported Data types:
            for i = 1 : length(SFContent.Data)
                d = SFContent.Data{i};
                if MatlabUtils.contains(d.Datatype, 'Enum:') ...
                        || MatlabUtils.contains(d.Datatype, 'Bus:')...
                        || MatlabUtils.contains(d.Datatype, 'fixdt')
                    obj.addUnsupported_options(...
                        sprintf('Data %s Scope %s Port %d in chart %s has unsupported Data Type "%s". Work in progress!' ,....
                        d.Name, d.Scope, d.Port, HtmlItem.addOpenCmd(blk.Origin_path), d.Datatype));
                end
            end
            %% get all events types and check for function call.
%             events = SFContent.Events;
%             for i=1:numel(events)
%                 if strcmp(events{i}.Trigger, 'Function call')
%                     obj.addUnsupported_options(...
%                         sprintf('Event "%s" in chart %s with "Function call" Trigger is not supported.',....
%                         events{i}.Name, HtmlItem.addOpenCmd(blk.Origin_path)));
%                 end
%             end
            %% get all states unsupportedOptions
            states = SFContent.States;
            for i=1:numel(states)
                obj.addUnsupported_options(...
                    nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.getUnsupportedOptions(states{i}));
            end
            %% get all junctions unsupported Options
            Junctions = SFContent.Junctions;
            for i=1:numel(Junctions)
                obj.addUnsupported_options(...
                    nasa_toLustre.blocks.Stateflow.StateflowJunction_To_Lustre.getUnsupportedOptions(Junctions{i}));
            end
            %% get all transitions unsupported Options
            transitions = nasa_toLustre.blocks.Chart_To_Lustre.getAllTransitions(SFContent);
            for i=1:numel(transitions)
                obj.addUnsupported_options(...
                    nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getUnsupportedOptions(transitions{i}));
            end
            %% get all graphical functions unsupported Options
            graphicalFunctions = SFContent.GraphicalFunctions;
            gfunctionsNames =  {};
            for i=1:numel(graphicalFunctions)
                if ismember(graphicalFunctions{i}.Name, gfunctionsNames)
                    obj.addUnsupported_options(...
                        sprintf(['Chart %s has more than one Stateflow function with the same name "%s".'...
                        ' Please use unique names for all Stateflow Functions.'],....
                        HtmlItem.addOpenCmd(blk.Origin_path), ...
                        graphicalFunctions{i}.Name));
                else
                    gfunctionsNames{end+1} = graphicalFunctions{i}.Name;
                end
                obj.addUnsupported_options(...
                    nasa_toLustre.blocks.Stateflow.StateflowGraphicalFunction_To_Lustre.getUnsupportedOptions(graphicalFunctions{i}, blk));
            end
            
            %% get all TruthTables unsupported Optionse
            truthTables = SFContent.TruthTables;
            truthTablesNames =  {};
            for i=1:numel(truthTables)
                if ismember(truthTables{i}.Name, truthTablesNames)
                    obj.addUnsupported_options(...
                        sprintf(['Chart %s has more than one TruthTable with the same name "%s".'...
                        ' Please use unique names for all Stateflow Functions.'],....
                        HtmlItem.addOpenCmd(blk.Origin_path), ...
                        truthTables{i}.Name));
                else
                    truthTablesNames{end+1} = truthTables{i}.Name;
                end
                obj.addUnsupported_options(...
                    nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.getUnsupportedOptions(truthTables{i}, blk));
            end
            
            
            %% return options
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        transitions = getAllTransitions(SFContent)
        [main_node, external_nodes, external_libraries_i] = ...
            getChartNodes(parent, blk, main_sampleTime, lus_backend, coco_backend, xml_trace)
    end
end

