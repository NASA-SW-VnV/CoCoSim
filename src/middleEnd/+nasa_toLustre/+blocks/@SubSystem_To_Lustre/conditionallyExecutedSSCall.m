
function [codes, node_name, inputs, ExecutionCondVar] = ...
        conditionallyExecutedSSCall(parent, blk, ...
        node_name, inputs, ...
        isEnabledSubsystem, EnableShowOutputPortIsOn, ...
        isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerBlockDT, ...
        isActionSS)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    codes = {};
    node_name = strcat(node_name, '_automaton');
    % ExecutionCondName may be used by Merge block, keep it even if
    % not given as input to the automaton node.
    ExecutionCondName = SubSystem_To_Lustre.getExecutionCondName(blk);

    if isTriggered && isEnabledSubsystem
        blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
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
        [srcBlk, srcPort] =nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, 'ifaction');
        if ~isempty(srcBlk)
            [IfBlkOutputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, srcBlk);

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
            [Enableinputs] =nasa_toLustre.utils.SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
            inputs = [inputs, Enableinputs];
        end
        if TriggerShowOutputPortIsOn
            lusIncomingSignalDataType =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Trigger{1});
            [lusTriggerportDataType] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(TriggerBlockDT);
            [triggerInputs] =nasa_toLustre.utils.SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
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
            [lusEnableportDataType, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(enableportDataType);
            enableInputs =nasa_toLustre.utils.SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
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
            [lusTriggerportDataType, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(triggerportDataType);
            [triggerInputs] =nasa_toLustre.utils.SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            cond = cell(1, blk.CompiledPortWidths.Trigger);
            for i=1:blk.CompiledPortWidths.Trigger
                [triggerCode, status] =nasa_toLustre.utils.SLX2LusUtils.getResetCode(...
                    TriggerType, lusTriggerportDataType, triggerInputs{i} , zero);
                if status
                    display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                        TriggerType, HtmlItem.addOpenCmd(blk.Origin_path)), ...
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
