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
classdef SubSystem_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %SubSystem_To_Lustre translates a subsystem (pottentially Conditional SS) call to Lustre.

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            codes = {};
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            
            if isInsideContract && numel(outputs) > 1 && coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
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
            
            try
                if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend) ...
                        && isfield(blk, 'CompiledSampleTime') ...
                        && isfield(parent, 'CompiledSampleTime')
                    [inTs, inTsOffset] = ...
                        nasa_toLustre.utils.SLX2LusUtils.getSSSampleTime(parent.CompiledSampleTime, main_sampleTime);
                    [outTs, outTsOffset] = ...
                        nasa_toLustre.utils.SLX2LusUtils.getSSSampleTime(blk.CompiledSampleTime, main_sampleTime);
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
            clocks_list =nasa_toLustre.utils.SLX2LusUtils.getRTClocksSTR(...
                blk, main_sampleTime);
            if ~coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend) && ~isempty(clocks_list)
                clocks_var = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x), ...
                    clocks_list, 'UniformOutput', 0);
                % add clocks in the begining of the inputs
                inputs = [clocks_var, inputs];
                % add clocks in the end of the inputs
                %extra_inputs = [extra_inputs, clocks_var];
            end
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
                if coco_nasa_utils.LusBackendType.isJKIND(lus_backend)
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
            % TruthTable and others are of blockType Subsystem but with no content.
            % They should be supported directly to Lustre
            if isempty(fieldnames(blk.Content)) && isfield(blk, 'SFBlockType') ...
                    && ~isempty(blk.SFBlockType)
                obj.addUnsupported_options(sprintf('Block "%s" with Type "%s" is not supported', ...
                    HtmlItem.addOpenCmd(blk.Origin_path), blk.SFBlockType));
            end
            if isempty(fieldnames(blk.Content)) && isfield(blk, 'MaskType') ...
                    && ~isempty(blk.MaskType)
                obj.addUnsupported_options(sprintf('Block "%s" with Type "%s" is not supported', ...
                    HtmlItem.addOpenCmd(blk.Origin_path), blk.MaskType));
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

