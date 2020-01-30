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
function [codes, node_name, inputs, ExecutionCondVar] = ...
        conditionallyExecutedSSCall(parent, blk, ...
        node_name, inputs, ...
        isEnabledSubsystem, EnableShowOutputPortIsOn, ...
        isTriggered, TriggerShowOutputPortIsOn, TriggerType, TriggerBlockDT, ...
        isActionSS)

    
    
    codes = {};
    node_name = strcat(node_name, '_condExecSS');
    %node_name = strcat(node_name, '_automaton');
    % ExecutionCondName may be used by Merge block, keep it even if
    % not given as input to the automaton node.
    ExecutionCondName = nasa_toLustre.blocks.SubSystem_To_Lustre.getExecutionCondName(blk);

    if isTriggered && isEnabledSubsystem
        blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
        EnableCondName = sprintf('EnableCond_of_%s', blk_name);
        TriggerCondName = sprintf('TriggerCond_of_%s', blk_name);
        ExecutionCondVar = {nasa_toLustre.lustreAst.LustreVar(ExecutionCondName, 'bool'), ...
            nasa_toLustre.lustreAst.LustreVar(TriggerCondName, 'bool'), ...
            nasa_toLustre.lustreAst.LustreVar(EnableCondName, 'bool')};
    else
        ExecutionCondVar = nasa_toLustre.lustreAst.LustreVar(ExecutionCondName, 'bool');...
    end
    if isActionSS
        % The case of Action subsystems
        [srcBlk, srcPort] =nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, 'ifaction');
        if ~isempty(srcBlk)
            [IfBlkOutputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, srcBlk);

            %codes{end + 1} = sprintf('%s = %s;\n\t'...
            %   ,ExecutionCondName,  IfBlkOutputs{srcPort});
            codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName), ...
                IfBlkOutputs{srcPort});
            inputs{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName);
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
                Triggercond = nasa_toLustre.lustreAst.VarIdExpr(TriggerCondName);
            else
                Triggercond = nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName);
            end
            for i=1:blk.CompiledPortWidths.Trigger
                TriggerinputsExp{i} = ...
                    nasa_toLustre.blocks.SubSystem_To_Lustre.getTriggerValue(Triggercond,...
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
                    cond{i} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
                                        enableInputs{i}, ...
                                        zero);
                end
            end
            EnableCond = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, cond);
        end
        triggerCond = {};
        if isTriggered
            triggerportDataType = blk.CompiledPortDataTypes.Trigger{1};
            [lusTriggerportDataType, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(triggerportDataType);
            [triggerInputs] =nasa_toLustre.utils.SLX2LusUtils.getSubsystemTriggerInputsNames(parent, blk);
            cond = cell(1, blk.CompiledPortWidths.Trigger);
            for i=1:blk.CompiledPortWidths.Trigger
                [triggerCode, status] =nasa_toLustre.utils.SLX2LusUtils.getTriggerCond(...
                    TriggerType, lusTriggerportDataType, triggerInputs{i} , zero);
                if status
                    display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                        TriggerType, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                        MsgType.ERROR, 'Constant_To_Lustre', '');
                    return;
                end
                cond{i} = triggerCode;
            end
            triggerCond = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, cond);
        end
        if isTriggered && isEnabledSubsystem

            %codes{end + 1} = sprintf('%s = %s;\n\t'...
            %    ,EnableCondName,  EnableCond);
            codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr(EnableCondName), ...
                EnableCond);
            %codes{end + 1} = sprintf('%s = %s;\n\t'...
            %    ,TriggerCondName,  triggerCond);
            codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr(TriggerCondName), ...
                triggerCond);
            %codes{end + 1} = sprintf('%s = %s and %s;\n\t'...
            %    ,ExecutionCondName,  EnableCondName, TriggerCondName);
            codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName), ...
                nasa_toLustre.lustreAst.BinaryExpr( nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                            nasa_toLustre.lustreAst.VarIdExpr(EnableCondName),...
                            nasa_toLustre.lustreAst.VarIdExpr(TriggerCondName)));
            inputs{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(EnableCondName);
            inputs{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(TriggerCondName);
            % add ExecutionCondName for Merge block.

        else
            if isTriggered
                %codes{end + 1} = sprintf('%s = %s;\n\t'...
                %    ,ExecutionCondName,  triggerCond);
                codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
                    nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName), ...
                    triggerCond);
            else
                %codes{end + 1} = sprintf('%s = %s;\n\t'...
                %    ,ExecutionCondName,  EnableCond);
                codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
                    nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName), ...
                    EnableCond);
            end
            inputs{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(ExecutionCondName);
        end

    end
end
