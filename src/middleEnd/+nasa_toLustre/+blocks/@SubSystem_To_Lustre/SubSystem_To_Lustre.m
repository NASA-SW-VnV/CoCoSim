classdef SubSystem_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
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
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] =...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            codes = {};
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            maskType = '';
            if isInsideContract && isfield(blk, 'MaskType')
                maskType = blk.MaskType;
            end
            if isInsideContract && numel(outputs) > 1
                display_msg(...
                    sprintf('Subsystem %s has more than one outputs. All Subsystems inside Contract should have one output.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'SubSystem_To_Lustre', '')
                return;
            end
            if isempty(blk.CompiledPortWidths.Outport) ...
                    && isfield(blk, 'MaskType') ...
                    && isequal(blk.MaskType, 'VerificationSubsystem')
                outputs{1} = VarIdExpr(strcat(node_name, '_virtual'));
            end
            %% Check Enable, Trigger, Action case
            [isEnabledSubsystem, EnableShowOutputPortIsOn] = ...
                SubSystem_To_Lustre.hasEnablePort(blk);
            [isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT] = ...
                SubSystem_To_Lustre.hasTriggerPort(blk);
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
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
            clocks_list =nasa_toLustre.utils.SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
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
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            [outputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            if isInsideContract && numel(outputs) > 1
                obj.addUnsupported_options(...
                    sprintf('Subsystem %s has more than one outputs. All Subsystems inside Contract should have one output.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)))
            end
            [isTriggered, ~, TriggerType, ~] = ...
                SubSystem_To_Lustre.hasTriggerPort(blk);
            if isTriggered
                if ~SLX2LusUtils.resetTypeIsSupported(TriggerType)
                    obj.addUnsupported_options(sprintf('This External Trigger type [%s] is not supported in block %s.', ...
                        TriggerType, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            [isResetSubsystem, ResetType] =SubSystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                if ~SLX2LusUtils.resetTypeIsSupported(ResetType)
                    obj.addUnsupported_options(sprintf('This External reset type [%s] is not supported in block %s.', ...
                        ResetType, HtmlItem.addOpenCmd(blk.Origin_path)));
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
        code = contractBlkCode(parent, blk, node_name, inputs, ...
                outputs, maskType, xml_trace)
        %%
        [b, hasNoOutputs, vsBlk] = hasVerificationSubsystem(blk)

        [b, ShowOutputPortIsOn, StatesWhenEnabling] = hasEnablePort(blk)
        
        [b, StatesWhenEnabling] = hasActionPort(blk)
        
        [b, ResetType] = hasResetPort(blk)

        [b, ShowOutputPortIsOn, TriggerType, TriggerDT] = hasTriggerPort(blk)

        [b, Iteratorblk] = hasForIterator(blk)
        %%
        ExecutionCondName = getExecutionCondName(blk)

        [codes, node_name, inputs, ExecutionCondVar] = ...
                conditionallyExecutedSSCall(parent, blk, ...
                node_name, inputs, ...
                isEnabledSubsystem, EnableShowOutputPortIsOn, ...
                isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerBlockDT, ...
                isActionSS)

        [codes, ResetCondVar] = ResettableSSCall(parent, blk, ...
                node_name, blk_name, ...
                ResetType, codes, inputs, outputs)
        %% trigger value
        TriggerinputExp = getTriggerValue(Cond, triggerInput, ...
                TriggerType, TriggerBlockDt, IncomingSignalDT)
    end
end

