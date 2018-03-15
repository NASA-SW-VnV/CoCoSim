classdef Subsystem_To_Lustre < Block_To_Lustre
    %Subsystem_To_Lustre translates a subsystem call to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name = SLX2LusUtils.node_name_format(blk);
            codes = {};
            [isEnabledSubsystem, EnableShowOutputPortIsOn] = ...
                Subsystem_To_Lustre.hasEnablePort(blk);
            [isTriggered, TriggerShowOutputPortIsOn, TriggerType] = ...
                Subsystem_To_Lustre.hasTriggerPort(blk);
            blk_name = SLX2LusUtils.name_format(blk.Name);
            if isEnabledSubsystem || isTriggered
                node_name = strcat(node_name, '_automaton');
                EnableCondName = sprintf('EnableCond_of_%s', blk_name);
                if EnableShowOutputPortIsOn
                    [Enableinputs] = SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
                    inputs = [inputs, Enableinputs];
                end
                if TriggerShowOutputPortIsOn
                    triggerportDataType = blk.CompiledPortDataTypes.Trigger{1};
                    [lusTriggerportDataType] = SLX2LusUtils.get_lustre_dt(triggerportDataType);
                    [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
                    TriggerinputsExp = {};
                    for i=1:blk.CompiledPortWidths.Trigger
                        TriggerinputsExp{i} = ...
                            SLX2LusUtils.getTriggerValue(EnableCondName,...
                            triggerInputs{i}, TriggerType, lusTriggerportDataType);
                    end
                    inputs = [inputs, TriggerinputsExp];
                end
                
                EnableCondVar = sprintf('%s:bool;', EnableCondName);
                obj.addVariable(EnableCondVar);
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
                    if ~strcmp(EnableCond, '')
                        EnableCond = sprintf('(%s) and (%s)', ...
                            EnableCond, triggerCond);
                    else
                        EnableCond = triggerCond;
                    end
                end
                codes{end + 1} = sprintf('%s = %s;\n\t'...
                    ,EnableCondName,  EnableCond);
                inputs{end + 1} = EnableCondName;
            end
            x = MatlabUtils.strjoin(inputs, ',\n\t\t');
            y = MatlabUtils.strjoin(outputs, ',\n\t');
            
            [isResetSubsystem, ResetType] =Subsystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                ResetCondName = sprintf('ResetCond_of_%s', blk_name);
                ResetCondVar = sprintf('%s:bool;', ResetCondName);
                obj.addVariable(ResetCondVar);
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
                    y, node_name, x, ResetCondName);
            else
                codes{numel(codes) + 1} = ...
                    sprintf('(%s) = %s(%s);\n\t', y, node_name, x);
            end
            
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    methods (Static = true)
        function [b, ShowOutputPortIsOn] = hasEnablePort(blk)
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
            else
                ShowOutputPortIsOn = 0;
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
        function [b, ShowOutputPortIsOn, TriggerType] = hasTriggerPort(blk)
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
            else
                ShowOutputPortIsOn = 0;
                TriggerType = '';
            end
        end
    end
end

