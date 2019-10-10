classdef SubSystem_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %SubSystem_To_Lustre translates a subsystem (pottentially Conditional SS) call to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            codes = {};
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            
            if isInsideContract && numel(outputs) > 1 && LusBackendType.isKIND2(lus_backend)
                display_msg(...
                    sprintf('Subsystem %s has more than one outputs. All Subsystems inside Contract should have one output.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'SubSystem_To_Lustre', '')
                return;
            end
            if isempty(blk.CompiledPortWidths.Outport) ...
                    && isfield(blk, 'MaskType') ...
                    && strcmp(blk.MaskType, 'VerificationSubsystem')
                outputs{1} = nasa_toLustre.lustreAst.VarIdExpr(strcat(node_name, '_virtual'));
            end
            %% Check Enable, Trigger, Action case
            [isEnabledSubsystem, EnableShowOutputPortIsOn] = ...
                nasa_toLustre.blocks.SubSystem_To_Lustre.hasEnablePort(blk);
            [isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT] = ...
                nasa_toLustre.blocks.SubSystem_To_Lustre.hasTriggerPort(blk);
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            [isActionSS, ~] = nasa_toLustre.blocks.SubSystem_To_Lustre.hasActionPort(blk);
            [isForIteraorSS, ~] = nasa_toLustre.blocks.SubSystem_To_Lustre.hasForIterator(blk);
            if isEnabledSubsystem || isTriggered || isActionSS
                [codes, node_name, inputs, EnableCondVar] = ...
                    nasa_toLustre.blocks.SubSystem_To_Lustre.conditionallyExecutedSSCall(parent, blk, ...
                    node_name, inputs, ...
                    isEnabledSubsystem, EnableShowOutputPortIsOn, ...
                    isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerDT, ...
                    isActionSS);
                obj.addVariable(EnableCondVar);
            elseif isForIteraorSS
                node_name = strcat(node_name, '_iterator');
            end
            
            %% add time input and clocks
            extra_inputs = {};
            extra_inputs{1} = ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
            extra_inputs{2} = ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                nasa_toLustre.utils.SLX2LusUtils.nbStepStr());
            clocks_list =nasa_toLustre.utils.SLX2LusUtils.getRTClocksSTR(...
                blk, main_sampleTime);
            if ~isempty(clocks_list)
                clocks_var = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x), ...
                    clocks_list, 'UniformOutput', 0);
                extra_inputs = [extra_inputs, clocks_var];
            end
            try
                if LusBackendType.isPRELUDE(lus_backend) ...
                        && isfield(blk, 'CompiledSampleTime') ...
                        && isfield(parent, 'CompiledSampleTime')
                    [inTs, inTsOffset] = ...
                        nasa_toLustre.utils.SLX2LusUtils.getSSSampleTime(parent.CompiledSampleTime);
                    [outTs, outTsOffset] = ...
                        nasa_toLustre.utils.SLX2LusUtils.getSSSampleTime(blk.CompiledSampleTime);
                    if (outTs ~= inTs || outTsOffset ~= inTsOffset)
                        c = outTs / inTs;
                        if outTs > inTs
                            for i=1:length(extra_inputs)
                                extra_inputs{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                                    nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_DIVIDE, ...
                                    extra_inputs{i}, ...
                                    nasa_toLustre.lustreAst.IntExpr(c));
                            end
                        end
                        % add offset
                        if outTsOffset ~= 0
                            normalizedOutT = outTs / inTs(1);
                            normalizedOutP = outTsOffset / inTs(1);
                            for i=1:length(extra_inputs)
                                extra_inputs{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                                    nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_OFFSET, ...
                                    extra_inputs{i}, ...
                                    nasa_toLustre.lustreAst.BinaryExpr(...
                                    nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                                    nasa_toLustre.lustreAst.IntExpr(normalizedOutP), ...
                                    nasa_toLustre.lustreAst.IntExpr(normalizedOutT)));
                            end
                        end
                    end
                end
            catch me
                me
            end
            inputs = [inputs, extra_inputs];
            
            %% Check Resettable SS case
            [isResetSubsystem, ResetType] =nasa_toLustre.blocks.SubSystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                [codes, ResetCondVar] = ...
                    nasa_toLustre.blocks.SubSystem_To_Lustre.ResettableSSCall(parent, blk, ...
                    node_name, blk_name, ...
                    ResetType, codes, inputs, outputs);
                obj.addVariable(ResetCondVar);
            else
                codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(outputs,...
                    nasa_toLustre.lustreAst.NodeCallExpr(node_name, inputs));
            end
            
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, lus_backend, varargin)
            
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            [outputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            if isInsideContract && numel(outputs) > 1
                obj.addUnsupported_options(...
                    sprintf('Subsystem %s has more than one outputs. All Subsystems inside Contract should have one output.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)))
            end
            [isTriggered, ~, TriggerType, ~] = ...
                nasa_toLustre.blocks.SubSystem_To_Lustre.hasTriggerPort(blk);
            if isTriggered
                if ~nasa_toLustre.utils.SLX2LusUtils.resetTypeIsSupported(TriggerType)
                    obj.addUnsupported_options(sprintf('This External Trigger type [%s] is not supported in block %s.', ...
                        TriggerType, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            [isResetSubsystem, ResetType] =nasa_toLustre.blocks.SubSystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                if LusBackendType.isJKIND(lus_backend)
                    obj.addUnsupported_options(sprintf(...
                        ['Block "%s" is not supported by JKind model checker.', ...
                        ' The block has a "reset" option that resets the Subsystem internal memories. ', ...
                        'This optiont is supported by other model checks. ', ...
                        cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
                        HtmlItem.addOpenCmd(blk.Origin_path)));
                elseif ~nasa_toLustre.utils.SLX2LusUtils.resetTypeIsSupported(ResetType)
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

