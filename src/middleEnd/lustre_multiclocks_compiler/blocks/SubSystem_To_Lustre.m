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
        
        function  write_code(obj, parent, blk, xml_trace, main_sampleTime, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name = SLX2LusUtils.node_name_format(blk);
            codes = {};
            isInsideContract = SLX2LusUtils.isContractBlk(parent);
            maskType = '';
            if isInsideContract && isfield(blk, 'MaskType')
                maskType = blk.MaskType;
            end
            if isInsideContract && numel(outputs) > 1
                display_msg(...
                    sprintf('Subsystem %s has more than one outputs. All Subsystems inside Contract should have one output.', ...
                    blk.Origin_path), MsgType.ERROR, 'SubSystem_To_Lustre', '')
                return;
            end
            %% Check Enable, Trigger, Action case
            [isEnabledSubsystem, EnableShowOutputPortIsOn] = ...
                SubSystem_To_Lustre.hasEnablePort(blk);
            [isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT] = ...
                SubSystem_To_Lustre.hasTriggerPort(blk);
            blk_name = SLX2LusUtils.node_name_format(blk);
            [isActionSS, ~] = SubSystem_To_Lustre.hasActionPort(blk);
            [isForIteraorSS, ~] = SubSystem_To_Lustre.hasForIterator(blk);
            if isEnabledSubsystem || isTriggered || isActionSS
                [codes, node_name, inputs, EnableCondVar] = ...
                    SubSystem_To_Lustre.conditionallyExecutedSSCall(parent, blk, ...
                    node_name, inputs, ...
                    isEnabledSubsystem, EnableShowOutputPortIsOn, ...
                    isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT, ...
                    isActionSS);
                    obj.addVariable(EnableCondVar);
            elseif isForIteraorSS
                node_name = strcat(node_name, '_iterator');
            end
            
            %% add time input and clocks
            inputs{end + 1} = VarIdExpr(SLX2LusUtils.timeStepStr());
            inputs{end + 1} = VarIdExpr(SLX2LusUtils.nbStepStr());
            clocks_list = SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
            if ~isempty(clocks_list)
                clocks_var = cell(1, numel(clocks_list));
                for i=1:numel(clocks_list)
                    clocks_var{i} = VarIdExpr(...
                        clocks_list{i});
                end
                inputs = [inputs, clocks_var];
            end
            
            %% Check Resettable SS case
            [isResetSubsystem, ResetType] =SubSystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                [codes, ResetCondVar] = ...
                    SubSystem_To_Lustre.ResettableSSCall(parent, blk, ...
                    node_name, blk_name, ...
                    ResetType, codes, inputs, outputs);
                obj.addVariable(ResetCondVar);
            else
                if isInsideContract
                    codes{end + 1} = SubSystem_To_Lustre.contractBlkCode(...
                        parent, blk, node_name, inputs, outputs, maskType, xml_trace);
                else
                    codes{end + 1} = LustreEq(outputs,...
                        NodeCallExpr(node_name, inputs));
                end
            end
            
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt); 
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            isInsideContract = SLX2LusUtils.isContractBlk(parent);
            [outputs, ~] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            if isInsideContract && numel(outputs) > 1
                obj.addUnsupported_options(...
                    sprintf('Subsystem %s has more than one outputs. All Subsystems inside Contract should have one output.', ...
                    blk.Origin_path))
            end
            [isTriggered, ~, TriggerType, ~] = ...
                SubSystem_To_Lustre.hasTriggerPort(blk);
            if isTriggered
                if ~SLX2LusUtils.resetTypeIsSupported(TriggerType)
                    obj.addUnsupported_options(sprintf('This External Trigger type [%s] is not supported in block %s.', ...
                        TriggerType, blk.Origin_path));
                end
            end
            [isResetSubsystem, ResetType] =SubSystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                if ~SLX2LusUtils.resetTypeIsSupported(ResetType)
                    obj.addUnsupported_options(sprintf('This External reset type [%s] is not supported in block %s.', ...
                        ResetType, blk.Origin_path));
                end
            end
            % add your unsuported options list here
            options =obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods (Static = true)
        %%
        function code = contractBlkCode(parent, blk, node_name, inputs, outputs, maskType, xml_trace)
            if isequal(maskType, 'ContractGuaranteeBlock')
                code = ContractGuaranteeExpr(node_name, ...
                    NodeCallExpr(node_name, inputs));
                xml_trace.add_Property(...
                    blk.Origin_path, ...
                    SLX2LusUtils.node_name_format(parent), node_name, 1, 'guarantee')
            elseif isequal(maskType, 'ContractAssumeBlock')
                code = ContractAssumeExpr(node_name, ...
                    NodeCallExpr(node_name, inputs));
                xml_trace.add_Property(...
                    blk.Origin_path, ...
                    SLX2LusUtils.node_name_format(parent), node_name, 1, 'assume')
            else
                if isequal(maskType, 'ContractEnsureBlock')
                    xml_trace.add_Property(...
                        blk.Origin_path, ...
                        SLX2LusUtils.node_name_format(parent), node_name, 1, 'ensure')
                elseif isequal(maskType, 'ContractRequireBlock')
                    xml_trace.add_Property(...
                        blk.Origin_path, ...
                        SLX2LusUtils.node_name_format(parent), node_name, 1, 'require')
                end
                code = LustreEq(outputs, ...
                    NodeCallExpr(node_name, inputs));
            end
        end
        %%
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
        function [b, StatesWhenStarting] = hasForIterator(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            forIteratorFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ForIterator'), fields));
            b = ~isempty(forIteratorFields);
            
            if b
                StatesWhenStarting = blk.Content.(forIteratorFields{1}).ResetStates;
            else
                StatesWhenStarting = '';
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
                ExecutionCondVar = {LustreVar(ExecutionCondName, 'bool'), ...
                    LustreVar(TriggerCondName, 'bool'), ...
                    LustreVar(EnableCondName, 'bool')};
            else
                ExecutionCondVar = LustreVar(ExecutionCondName, 'bool');...
            end
            if isActionSS
                % The case of Action subsystems
                [srcBlk, srcPort] = SLX2LusUtils.getpreBlock(parent, blk, 'ifaction');
                if ~isempty(srcBlk)
                    [IfBlkOutputs, ~] = SLX2LusUtils.getBlockOutputsNames(parent, srcBlk);

                    %codes{end + 1} = sprintf('%s = %s;\n\t'...
                    %   ,ExecutionCondName,  IfBlkOutputs{srcPort});
                    codes{end + 1} = LustreEq(...
                        VarIdExpr(ExecutionCondName), ...
                        IfBlkOutputs{srcPort});
                    inputs{end + 1} = VarIdExpr(ExecutionCondName);
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
                    TriggerinputsExp = cell(1, blk.CompiledPortWidths.Trigger);
                    if isTriggered && isEnabledSubsystem
                        Triggercond = VarIdExpr(TriggerCondName);
                    else
                        Triggercond = VarIdExpr(ExecutionCondName);
                    end
                    for i=1:blk.CompiledPortWidths.Trigger
                        TriggerinputsExp{i} = ...
                            SubSystem_To_Lustre.getTriggerValue(Triggercond,...
                            triggerInputs{i}, TriggerType, lusTriggerportDataType, lusIncomingSignalDataType);
                    end
                    inputs = [inputs, TriggerinputsExp];
                end
                
                
                EnableCond = {};
                if isEnabledSubsystem
                    enableportDataType = blk.CompiledPortDataTypes.Enable{1};
                    [lusEnableportDataType, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                    enableInputs = SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
                    cond = cell(1, blk.CompiledPortWidths.Enable);
                    for i=1:blk.CompiledPortWidths.Enable
                        if strcmp(lusEnableportDataType, 'bool')
                            cond{i} =  enableInputs{i};
                        else
                            cond{i} = BinaryExpr(BinaryExpr.GT, ...
                                                enableInputs{i}, ...
                                                zero);
                        end
                    end
                    EnableCond = BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, cond);
                end
                triggerCond = {};
                if isTriggered
                    triggerportDataType = blk.CompiledPortDataTypes.Trigger{1};
                    [lusTriggerportDataType, zero] = SLX2LusUtils.get_lustre_dt(triggerportDataType);
                    [triggerInputs] = SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
                    cond = cell(1, blk.CompiledPortWidths.Trigger);
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
                    triggerCond = BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, cond);
                end
                if isTriggered && isEnabledSubsystem

                    %codes{end + 1} = sprintf('%s = %s;\n\t'...
                    %    ,EnableCondName,  EnableCond);
                    codes{end + 1} = LustreEq(...
                        VarIdExpr(EnableCondName), ...
                        EnableCond);
                    %codes{end + 1} = sprintf('%s = %s;\n\t'...
                    %    ,TriggerCondName,  triggerCond);
                    codes{end + 1} = LustreEq(...
                        VarIdExpr(TriggerCondName), ...
                        triggerCond);
                    %codes{end + 1} = sprintf('%s = %s and %s;\n\t'...
                    %    ,ExecutionCondName,  EnableCondName, TriggerCondName);
                    codes{end + 1} = LustreEq(...
                        VarIdExpr(ExecutionCondName), ...
                        BinaryExpr( BinaryExpr.AND, ...
                                    VarIdExpr(EnableCondName),...
                                    VarIdExpr(TriggerCondName)));
                    inputs{end + 1} = VarIdExpr(EnableCondName);
                    inputs{end + 1} = VarIdExpr(TriggerCondName);
                    % add ExecutionCondName for Merge block.
                    
                else
                    if isTriggered
                        %codes{end + 1} = sprintf('%s = %s;\n\t'...
                        %    ,ExecutionCondName,  triggerCond);
                        codes{end + 1} = LustreEq(...
                            VarIdExpr(ExecutionCondName), ...
                            triggerCond);
                    else
                        %codes{end + 1} = sprintf('%s = %s;\n\t'...
                        %    ,ExecutionCondName,  EnableCond);
                        codes{end + 1} = LustreEq(...
                            VarIdExpr(ExecutionCondName), ...
                            EnableCond);
                    end
                    inputs{end + 1} = VarIdExpr(ExecutionCondName);
                end
                
            end
        end
        function [codes, ResetCondVar] = ResettableSSCall(parent, blk, ...
                node_name, blk_name, ...
                ResetType, codes, inputs, outputs)
            ResetCondName = sprintf('ResetCond_of_%s', blk_name);
            ResetCondVar = LustreVar(ResetCondName, 'bool');
            resetportDataType = blk.CompiledPortDataTypes.Reset{1};
            [lusResetportDataType, zero] = SLX2LusUtils.get_lustre_dt(resetportDataType);
            resetInputs = SLX2LusUtils.getSubsystemResetInputsNames(parent, blk);
            cond = cell(1, blk.CompiledPortWidths.Reset);
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
            ResetCond = BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, cond);
            %codes{end + 1} = sprintf('%s = %s;\n\t'...
            %    ,ResetCondName,  ResetCond);
            codes{end + 1} = LustreEq(VarIdExpr(ResetCondName), ResetCond);
            codes{end + 1} = ...
                LustreEq(outputs, ...
                EveryExpr(node_name, inputs, VarIdExpr(ResetCondName)));
        end
        %% trigger value
        function TriggerinputExp = getTriggerValue(Cond, triggerInput, TriggerType, TriggerBlockDt, IncomingSignalDT)
            if strcmp(TriggerBlockDt, 'real')
                %suffix = '.0';
                zero = RealExpr('0.0');
                one = RealExpr('1.0');
                two = RealExpr('2.0');
            else
                %suffix = '';
                zero = IntExpr(0);
                one = IntExpr(1);
                two = IntExpr(2);
            end
            if strcmp(IncomingSignalDT, 'real')
                IncomingSignalzero = RealExpr('0.0');
            else
                IncomingSignalzero = IntExpr(0);
            end
            if strcmp(TriggerType, 'rising')
%                 sprintf(...
%                     '0%s -> if %s then 1%s else 0%s'...
%                     ,suffix, Cond, suffix, suffix );
                TriggerinputExp = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    zero, ...
                    IteExpr(Cond, one, zero)) ;
            elseif strcmp(TriggerType, 'falling')
%                 TriggerinputExp = sprintf(...
%                     '0%s -> if %s then -1%s else 0%s'...
%                     ,suffix, Cond, suffix, suffix );
                TriggerinputExp = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    zero, ...
                    IteExpr(Cond, ...
                            UnaryExpr(UnaryExpr.NEG, one),...
                            zero)) ;
            elseif strcmp(TriggerType, 'function-call')
%                 TriggerinputExp = sprintf(...
%                     '0%s -> if %s then 2%s else 0%s'...
%                     ,suffix, Cond, suffix, suffix );
                TriggerinputExp = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    zero, ...
                    IteExpr(Cond, ...
                            two,...
                            zero)) ;
            else
                risingCond = SLX2LusUtils.getResetCode(...
                    'rising', IncomingSignalDT, triggerInput, IncomingSignalzero );
%                 TriggerinputExp = sprintf(...
%                     '%s -> if %s then (if (%s) then 1%s else -1%s) else 0%s'...
%                     ,zero,  Cond, risingCond, suffix, suffix, suffix);
                TriggerinputExp = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    zero, ...
                    IteExpr(Cond, ...
                            IteExpr(risingCond, one, UnaryExpr(UnaryExpr.NEG, one)),...
                            zero)) ;
            end
        end
    end
end

