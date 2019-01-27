classdef Chart_To_Lustre < Block_To_Lustre
    % Chart_To_Lustre translates Stateflow chart to Lustre.
    % This version is temporal using the old compiler. New version using
    % lustref compiler is comming soon.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
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
                node_name = SLX2LusUtils.node_name_format(blk);
            end
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            codes = {};
            if ~isempty(triggerInputs)
                cond = cell(1, blk.CompiledPortWidths.Trigger);
                for i=1:blk.CompiledPortWidths.Trigger
                    TriggerType = blk.StateflowContent.Events{i}.Trigger;
                    [lusTriggerportDataType, zero] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Trigger{1});
                    [triggerCode, status] = SLX2LusUtils.getResetCode(...
                        TriggerType, lusTriggerportDataType, triggerInputs{i} , zero);
                    if status
                        display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                            TriggerType, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                            MsgType.ERROR, 'Constant_To_Lustre', '');
                        return;
                    end
                    v_name = sprintf('%s_Event%d', node_name, i);
                    obj.addVariable(LustreVar(v_name, 'bool'));
                    codes{end+1} = LustreEq(VarIdExpr(v_name), triggerCode);
                    cond{i} = VarIdExpr(v_name);
                end
                inputs = [cond, inputs];
            end
            if isempty(inputs)
                inputs{1} = BooleanExpr(true);
            end
            
            
            codes{end+1} = LustreEq(outputs, NodeCallExpr(node_name, inputs));
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            SFContent = blk.StateflowContent;
            %% Check chart properties
            %Action language for programming the chart. Can be C or MATLAB.
            if isequal(SFContent.ActionLanguage, 'C')
                obj.addUnsupported_options(...
                    sprintf(['Action Language "C" for chart %s is not supported. You need to set Action Language to "Matlab".'...
                    '\nYou can change the action language by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %Type of state machine to create. Default is Classic, 
            %which provides the full set of semantics for MATLAB charts 
            %and C charts. You can also create Mealy and Moore charts, 
            %which use a subset of Stateflow chart semantics 
            if isequal(SFContent.StateMachineType, 'Moore')
                obj.addUnsupported_options(...
                    sprintf(['State MachineType "Moore" for chart %s is not supported. You need to use different State MachineType.'...
                    '\nYou can change the State MachineType by Right-click in an empty area of the chart and select Properties.'],....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            %Activation method of this chart. Can be 'INHERITED' (default), 
            %'DISCRETE', or 'CONTINUOUS'.
            if isequal(SFContent.ChartUpdate, 'CONTINUOUS')
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
            if ~isempty(SFContent.TruthTables)
                obj.addUnsupported_options(...
                    sprintf('Stateflow TruthTables in chart %s are not supported. Work in progress!' ,....
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            %% Check data dimenstion
%             InportsWidth = blk.CompiledPortWidths.Inport;
%             for i=1:numel(InportsWidth)
%                 if InportsWidth(i) > 1
%                     obj.addUnsupported_options(...
%                         sprintf(['Inport number %d in block %s is not a '...
%                         'scalar. Only scalar inputs are supported in Stateflow chart.'],....
%                         i, HtmlItem.addOpenCmd(blk.Origin_path)));
%                 end
%             end
%             OutportsWidth = blk.CompiledPortWidths.Outport;
%             for i=1:numel(OutportsWidth)
%                 if OutportsWidth(i) > 1
%                     obj.addUnsupported_options(...
%                         sprintf(['Outport number %d in block %s is not a '...
%                         'scalar. Only scalar outputs are supported in Stateflow chart.'],....
%                         i, HtmlItem.addOpenCmd(blk.Origin_path)));
%                 end
%             end
%             data = SFContent.Data;
%             for i=1:numel(data)
%                 ArraySize = str2num(data{i}.CompiledSize);
%                 if ~isempty(ArraySize) && ArraySize > 1
%                     obj.addUnsupported_options(...
%                         sprintf(['Data "%s" in chart %s is not a '...
%                         'scalar. Only scalar data are supported in Stateflow chart.'],....
%                         data{i}.Name, HtmlItem.addOpenCmd(blk.Origin_path)));
%                 end
%             end
            %% get all events types and check for function call.
            events = SFContent.Events;
            for i=1:numel(events)
                if isequal(events{i}.Trigger, 'Function call')
                    obj.addUnsupported_options(...
                        sprintf('Event "%s" in chart %s with "Function call" Trigger is not supported.',....
                        events{i}.Name, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            %% get all states unsupportedOptions
            states = SFContent.States;
            for i=1:numel(states)
                obj.addUnsupported_options(...
                    StateflowState_To_Lustre.getUnsupportedOptions(states{i}));
            end
            %% get all junctions unsupported Options
            Junctions = SFContent.Junctions;
            for i=1:numel(Junctions)
                obj.addUnsupported_options(...
                    StateflowJunction_To_Lustre.getUnsupportedOptions(Junctions{i}));
            end
            %% get all transitions unsupported Options
            transitions = Chart_To_Lustre.getAllTransitions(SFContent);
            for i=1:numel(transitions)
                obj.addUnsupported_options(...
                    StateflowTransition_To_Lustre.getUnsupportedOptions(transitions{i}));
            end
            %% get all graphical functions unsupported Options
            graphicalFunctions = SFContent.GraphicalFunctions;
            for i=1:numel(graphicalFunctions)
                obj.addUnsupported_options(...
                    StateflowGraphicalFunction_To_Lustre.getUnsupportedOptions(graphicalFunctions{i}, blk));
            end
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        function transitions = getAllTransitions(SFContent)
            transitions = {};
            for i=1:numel(SFContent.States)
                transitions = [transitions, ...
                    SFContent.States{i}.Composition.DefaultTransitions];
                transitions = [transitions, ...
                    SFContent.States{i}.OuterTransitions];
                transitions = [transitions, ...
                    SFContent.States{i}.InnerTransitions];
            end
            for i=1:numel(SFContent.Junctions)
                transitions = [transitions, ...
                    SFContent.Junctions{i}.OuterTransitions];
            end
            for i=1:numel(SFContent.GraphicalFunctions)
                transitions = [transitions, ...
                    Chart_To_Lustre.getAllTransitions(SFContent.GraphicalFunctions{i})];
            end
        end
    end
end

