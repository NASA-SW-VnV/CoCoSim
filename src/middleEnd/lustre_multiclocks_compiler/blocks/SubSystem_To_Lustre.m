classdef SubSystem_To_Lustre < Block_To_Lustre
    %SubSystem_To_Lustre translates a subsystem (pottentially Conditional SS) call to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, main_sampleTime, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name = SLX2LusUtils.node_name_format(blk);
            codes = {};
            
            %% Check Enable, Trigger, Action case
            [isEnabledSubsystem, EnableShowOutputPortIsOn] = ...
                SubSystem_To_Lustre.hasEnablePort(blk);
            [isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT] = ...
                SubSystem_To_Lustre.hasTriggerPort(blk);
            blk_name = SLX2LusUtils.node_name_format(blk);
            [isActionSS, ~] = SubSystem_To_Lustre.hasActionPort(blk);
            if isEnabledSubsystem || isTriggered || isActionSS
                [codes, node_name, inputs, EnableCondVar] = ...
                    SubSystem_To_Lustre.conditionallyExecutedSSCall(parent, blk, ...
                    node_name, inputs, ...
                    isEnabledSubsystem, EnableShowOutputPortIsOn, ...
                    isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT, ...
                    isActionSS);
                obj.addVariable(EnableCondVar);
            end
            
            %% add time input and clocks
            inputs{end + 1} = SLX2LusUtils.timeStepStr();
            x = MatlabUtils.strjoin(inputs, ',\n\t\t');
            clocks_list = SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
            if ~isempty(clocks_list)
                x = [x ', ' clocks_list];
            end
            y = MatlabUtils.strjoin(outputs, ',\n\t');
            
            %% Check Resettable SS case
            [isResetSubsystem, ResetType] =SubSystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                [codes, ResetCondVar] = ...
                    SubSystem_To_Lustre.ResettableSSCall(parent, blk, ...
                    node_name, blk_name, ...
                    ResetType, codes, x, y);
                obj.addVariable(ResetCondVar);
            else
                codes{numel(codes) + 1} = ...
                    sprintf('(%s) = %s(%s);\n\t', y, node_name, x);
            end
            
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [isEnabledSubsystem, ~, StatesWhenEnabling] = ...
                SubSystem_To_Lustre.hasEnablePort(blk);
            [isTriggered, ~, ~] = ...
                SubSystem_To_Lustre.hasTriggerPort(blk);
            if isEnabledSubsystem && isTriggered && strcmp(StatesWhenEnabling, 'reset')
                obj.addUnsupported_options(...
                    sprintf('Subsystem %s has an EnablePort and TriggerPort, in this scenario we do not support "reset" option in the EnablePort. Please use held', ...
                    blk.Origin_path));
            end
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    methods (Static = true)
        function [b, ShowOutputPortIsOn, StatesWhenEnabling] = hasEnablePort(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            enablePortsFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'EnablePort'), fields));
            b = ~isempty(enablePortsFields);
            
            if b
                ShowOutputPortIsOn =  ...
                    strcmp(blk.Content.(enablePortsFields{1}).ShowOutputPort, 'on');
                StatesWhenEnabling = blk.Content.(enablePortsFields{1}).StatesWhenEnabling;
            else
                ShowOutputPortIsOn = 0;
                StatesWhenEnabling = '';
            end
        end
        
        function [b, StatesWhenEnabling] = hasActionPort(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            enablePortsFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ActionPort'), fields));
            b = ~isempty(enablePortsFields);
            
            if b
                StatesWhenEnabling = blk.Content.(enablePortsFields{1}).InitializeStates;
            else
                StatesWhenEnabling = '';
            end
        end
        
        function [b, ResetType] = hasResetPort(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            resetPortsFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ResetPort'), fields));
            b = ~isempty(resetPortsFields);
            
            if b
                ResetType = blk.Content.(resetPortsFields{1}).ResetTriggerType;
            else
                ResetType = '';
            end
        end
        function [b, ShowOutputPortIsOn, TriggerType, TriggerDT] = hasTriggerPort(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            triggerPortsFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'TriggerPort'), fields));
            b = ~isempty(triggerPortsFields);
            
            if b
                TriggerType = blk.Content.(triggerPortsFields{1}).TriggerType;
                ShowOutputPortIsOn =  ...
                    strcmp(blk.Content.(triggerPortsFields{1}).ShowOutputPort, 'on');
                if ShowOutputPortIsOn
                    TriggerDT = blk.Content.(triggerPortsFields{1}).CompiledPortDataTypes.Outport{1};
                else
                    TriggerDT = '';
                end
            else
                ShowOutputPortIsOn = 0;
                TriggerType = '';
                TriggerDT = '';
            end
        end
        %%
        function ExecutionCondName = getExecutionCondName(blk)
            blk_name = SLX2LusUtils.node_name_format(blk);
            ExecutionCondName = sprintf('ExecutionCond_of_%s', blk_name);
        end
        function [codes, node_name, inputs, ExecutionCondVar] = ...
                conditionallyExecutedSSCall(parent, blk, ...
                node_name, inputs, ...
                isEnabledSubsystem, EnableShowOutputPortIsOn, ...
                isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerBlockDT, ...
                isActionSS)
            codes = {};
            node_name = strcat(node_name, '_automaton');
            % ExecutionCondName may be used by Merge block, keep it even if
            % not given as input to the automaton node.
            ExecutionCondName = SubSystem_To_Lustre.getExecutionCondName(blk);
            
            if isTriggered && isEnabledSubsystem
                blk_name = SLX2LusUtils.node_name_format(blk);
                EnableCondName = sprintf('EnableCond_of_%s', blk_name);
                TriggerCondName = sprintf('TriggerCond_of_%s', blk_name);
                ExecutionCondVar = sprintf('%s, %s, %s:bool;', ...
                    ExecutionCondName, TriggerCondName, EnableCondName);
            else
                ExecutionCondVar = sprintf('%s:bool;', ExecutionCondName);
            end
            if isActionSS
                % The case of Action subsystems
                [srcBlk, srcPort] = SLX2LusUtils.getpreBlock(parent, blk, 'ifaction');
                if ~isempty(srcBlk)
                    [IfBlkOutputs, ~] = SLX2LusUtils.getBlockOutputsNames(parent, srcBlk);
                    codes{end + 1} = sprintf('%s = %s;\n\t'...
                        ,ExecutionCondName,  IfBlkOutputs{srcPort});
                    inputs{end + 1} = ExecutionCondName;
                end
            else
                % the case of enabled/triggered subsystems
                
                if EnableShowOutputPortIsOn
                    [Enableinputs] = SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
                    inputs = [inputs, Enableinputs];
                end
                if TriggerShowOutputPortIsOn
                    lusIncomingSignalDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Trigger{1});
                    [lusTriggerportDataType] = SLX2LusUtils.get_lustre_dt(TriggerBlockDT);
                    [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
                    TriggerinputsExp = {};
                    if isTriggered && isEnabledSubsystem
                        condName = TriggerCondName;
                    else
                        condName = ExecutionCondName;
                    end
                    for i=1:blk.CompiledPortWidths.Trigger
                        TriggerinputsExp{i} = ...
                            SLX2LusUtils.getTriggerValue(condName,...
                            triggerInputs{i}, TriggerType, lusTriggerportDataType, lusIncomingSignalDataType);
                    end
                    inputs = [inputs, TriggerinputsExp];
                end
                
                
                EnableCond = '';
                if isEnabledSubsystem
                    enableportDataType = blk.CompiledPortDataTypes.Enable{1};
                    [lusEnableportDataType, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                    enableInputs = SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
                    cond = {};
                    for i=1:blk.CompiledPortWidths.Enable
                        if strcmp(lusEnableportDataType, 'bool')
                            cond{i} = sprintf('%s', enableInputs{i});
                        else
                            cond{i} = sprintf('%s > %s', enableInputs{i}, zero);
                        end
                    end
                    EnableCond = MatlabUtils.strjoin(cond, ' or ');
                end
                triggerCond = '';
                if isTriggered
                    triggerportDataType = blk.CompiledPortDataTypes.Trigger{1};
                    [lusTriggerportDataType, zero] = SLX2LusUtils.get_lustre_dt(triggerportDataType);
                    [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
                    cond = {};
                    for i=1:blk.CompiledPortWidths.Trigger
                        [triggerCode, status] = SLX2LusUtils.getResetCode(...
                            TriggerType, lusTriggerportDataType, triggerInputs{i} , zero);
                        if status
                            display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                                TriggerType, blk.Origin_path), ...
                                MsgType.ERROR, 'Constant_To_Lustre', '');
                            return;
                        end
                        cond{i} = triggerCode;
                    end
                    triggerCond = MatlabUtils.strjoin(cond, ' or ');
                end
                if isTriggered && isEnabledSubsystem
                    codes{end + 1} = sprintf('%s = %s;\n\t'...
                        ,EnableCondName,  EnableCond);
                    codes{end + 1} = sprintf('%s = %s;\n\t'...
                        ,TriggerCondName,  triggerCond);
                    inputs{end + 1} = EnableCondName;
                    inputs{end + 1} = TriggerCondName;
                    % add ExecutionCondName for Merge block.
                    codes{end + 1} = sprintf('%s = %s and %s;\n\t'...
                        ,ExecutionCondName,  EnableCondName, TriggerCondName);
                else
                    if isTriggered
                        codes{end + 1} = sprintf('%s = %s;\n\t'...
                            ,ExecutionCondName,  triggerCond);
                    else
                        codes{end + 1} = sprintf('%s = %s;\n\t'...
                            ,ExecutionCondName,  EnableCond);
                    end
                    inputs{end + 1} = ExecutionCondName;
                end
                
            end
        end
        function [codes, ResetCondVar] = ResettableSSCall(parent, blk, ...
                node_name, blk_name, ...
                ResetType, codes, inputs, outputs)
            ResetCondName = sprintf('ResetCond_of_%s', blk_name);
            ResetCondVar = sprintf('%s:bool;', ResetCondName);
            resetportDataType = blk.CompiledPortDataTypes.Reset{1};
            [lusResetportDataType, zero] = SLX2LusUtils.get_lustre_dt(resetportDataType);
            resetInputs = SLX2LusUtils.getSubsystemResetInputsNames(parent, blk);
            cond = {};
            for i=1:blk.CompiledPortWidths.Reset
                [resetCode, status] = SLX2LusUtils.getResetCode(...
                    ResetType, lusResetportDataType, resetInputs{i} , zero);
                if status
                    display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                        ResetType, blk.Origin_path), ...
                        MsgType.ERROR, 'Constant_To_Lustre', '');
                    return;
                end
                cond{i} = resetCode;
            end
            ResetCond = MatlabUtils.strjoin(cond, ' or ');
            codes{numel(codes) + 1} = sprintf('%s = %s;\n\t'...
                ,ResetCondName,  ResetCond);
            
            codes{numel(codes) + 1} = ...
                sprintf('(%s) = %s(%s) every %s;\n\t', ...
                outputs, node_name, inputs, ResetCondName);
        end
    end
end

