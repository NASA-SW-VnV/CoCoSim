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
function [ external_nodes] = condExecSS_To_LusMerge( parent_ir, ss_ir, lus_backend, ...
        hasEnablePort, hasActionPort, hasTriggerPort, isContractBlk, main_sampleTime, xml_trace)
    %condExecSS_To_LusMerge create an external lustre node for
    %enabled/triggered/Action subsystem
    %INPUTS:
    %   ss_ir: The internal representation of the subsystem.
    

    %
    %
    
    
    % Adding lustre comments tracking the original path
    
    external_nodes = {};
    % creating node header
    if hasTriggerPort && hasEnablePort
        isEnableORAction = 0;
        isEnableAndTrigger = 1;
    else
        isEnableORAction = 1;
        isEnableAndTrigger = 0;
    end
    is_main_node = 0;
    isMatlabFunction = false;
    [blk_name, node_inputs, node_outputs,...
        node_inputs_withoutDT, node_outputs_withoutDT] = ...
        nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent_ir, ss_ir, is_main_node, ...
        isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction,...
        main_sampleTime, xml_trace);
    
    
    
    node_name = strcat(blk_name, '_condExecSS');
    
    
    % Body code
    original_node_call = ...
        nasa_toLustre.lustreAst.NodeCallExpr(blk_name, node_inputs_withoutDT);
    if isEnableAndTrigger
        % the case of enabledTriggered subsystem
        % we will create two nodes : one for trigger port only
        % the second call the first node inside Enable condition.
        % trigger node
        activate_cond = nasa_toLustre.utils.SLX2LusUtils.isTriggeredStr();
        [body_trigger, variables_trigger] = ...
            write_enabled_OR_triggered_OR_action_SS(ss_ir, lus_backend, ...
            node_outputs_withoutDT, false, false, true, ...
            activate_cond, original_node_call, main_sampleTime);
        trigger_node_name = strcat(blk_name, '_triggeredSS');
        trigger_node = nasa_toLustre.lustreAst.LustreNode(...
            '', ...
            trigger_node_name,...
            node_inputs, ...
            node_outputs, ...
            {}, ...
            variables_trigger, ...
            body_trigger, ...
            false);
        external_nodes{end+1} = trigger_node;
        % the enabled Triggered node: it calls the trigger_node.
        trigger_node_call = ...
            nasa_toLustre.lustreAst.NodeCallExpr(trigger_node_name, ...
            cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), node_inputs, 'un', 0));
        activate_cond = nasa_toLustre.utils.SLX2LusUtils.isEnabledStr();
        [body, variables] = write_enabled_OR_triggered_OR_action_SS(ss_ir, ...
            lus_backend, node_outputs_withoutDT,...
            true, false, false, activate_cond, trigger_node_call, main_sampleTime);
    else
        original_node_call = ...
            nasa_toLustre.lustreAst.NodeCallExpr(blk_name, node_inputs_withoutDT);
        activate_cond = nasa_toLustre.utils.SLX2LusUtils.isEnabledStr();
        [body, variables] = write_enabled_OR_triggered_OR_action_SS(ss_ir, lus_backend, ...
            node_outputs_withoutDT, hasEnablePort, hasActionPort,...
            hasTriggerPort, activate_cond, original_node_call, main_sampleTime);
        
    end
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Original block name: %s', ss_ir.Origin_path), true);
    main_node = nasa_toLustre.lustreAst.LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        variables, ...
        body, ...
        is_main_node);
    external_nodes{end+1} = main_node;
end


%%
function [body, variables_cell] =...
        write_enabled_OR_triggered_OR_action_SS(subsys, lus_backend,...
        node_outputs_withoutDT, hasEnablePort, hasActionPort, hasTriggerPort, ...
        activate_cond, original_node_call, main_sampleTime)
    %
    %
    
    fields = fieldnames(subsys.Content);
    
    if hasTriggerPort && ~(hasEnablePort && hasActionPort)
        %the case of trigger port only
        triggerPortsFields = fields(...
            cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
            && (strcmp(subsys.Content.(x).BlockType,'TriggerPort')) ), fields));
        triggerPort = subsys.Content.(triggerPortsFields{1});
        if ~strcmp(triggerPort.TriggerType, 'function-call')
            is_restart = false;% by default
        else
            is_restart = strcmp(triggerPort.StatesWhenEnabling, 'reset');
        end
        forceToHeld = is_restart;
    else
        enablePortsFields = fields(...
            cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
            && (strcmp(subsys.Content.(x).BlockType,'EnablePort') ...
            || strcmp(subsys.Content.(x).BlockType,'ActionPort')) ), fields));
        if hasEnablePort
            StatesWhenEnabling = subsys.Content.(enablePortsFields{1}).StatesWhenEnabling;
        else
            StatesWhenEnabling = subsys.Content.(enablePortsFields{1}).InitializeStates;
        end
        if strcmp(StatesWhenEnabling, 'reset')
            is_restart = true;
        else
            is_restart = false;
        end
        forceToHeld = false;
    end
    [body, variables_cell, pre_out_vars, InitialOutputs] = ...
        getPreOutputsCode(subsys, hasActionPort, hasEnablePort, forceToHeld, main_sampleTime);
    % example of generated code
    % Kind2 Syntax:
    % (node_outputs_withoutDT) = merge( _isEnabled ;
    %  (activate originalNodeName every _isEnabled restart every (_isEnabled and not pre _isEnabled))(inputs);
    %  (pre_NextState_1, 0.0-> pre I) when not _isEnabled ) ;
    %
    % Jkind Syntax:
    % (node_outputs_withoutDT) = condact(_isEnabled, originalNodeName(inputs), 0.0(*Initial Condition for first output*), 0.0(*Initial Condition for Second output*));
    
    if LusBackendType.isJKIND(lus_backend)
        if is_restart
            %Jkind does not have an operator to restart a node memory
            display_msg(sprintf(['Block "%s" is not supported by JKind model checker.', ...
                ' The block has a "reset" option when the Subsystem is reactivated. ', ...
                'This optiont is supported by the other model checks. ', ...
                cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
                HtmlItem.addOpenCmd(subsys.Origin_path)), ...
                MsgType.ERROR, 'condExecSS_To_LusMerge', '');
            return;
        else
            condact_args{1} = nasa_toLustre.lustreAst.VarIdExpr(activate_cond);
            condact_args{2} = original_node_call;
            condact_args = [condact_args, InitialOutputs];
            % No need for previous body
            body = {};
            % No need for previous vars
            variables_cell = {};
            % add call
            body{1} = nasa_toLustre.lustreAst.LustreEq(node_outputs_withoutDT,...
                nasa_toLustre.lustreAst.CondactExpr(condact_args));
        end
        
    else
        if LusBackendType.isKIND2(lus_backend)
            isEnabledVar =...
                nasa_toLustre.lustreAst.VarIdExpr(activate_cond);
        else
            enabled_clock_var_name = strcat(activate_cond, '_clock');
            variables_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
                enabled_clock_var_name, 'bool clock');
            isEnabledVar = nasa_toLustre.lustreAst.VarIdExpr(enabled_clock_var_name);
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(isEnabledVar, ...
                nasa_toLustre.lustreAst.VarIdExpr(activate_cond));
        end
        
        if is_restart
            reset_cond = nasa_toLustre.utils.SLX2LusUtils.getResetCode(...
                'rising', 'bool', isEnabledVar );
            if LusBackendType.isKIND2(lus_backend)
                restart_cond = reset_cond;
            else
                reset_clock_var_name = strcat(activate_cond, '_reset_clock');
                variables_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
                    reset_clock_var_name, 'bool clock');
                restart_cond = nasa_toLustre.lustreAst.VarIdExpr(...
                    reset_clock_var_name);
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(restart_cond, ...
                    reset_cond);
            end
        else
            restart_cond = {};
        end
        true_expr = nasa_toLustre.lustreAst.ActivateExpr(...
            original_node_call.getNodeName(), original_node_call.getArgs(), ...
            isEnabledVar, is_restart, restart_cond);
        addWhentrue = false;
        false_expr = nasa_toLustre.lustreAst.TupleExpr(pre_out_vars);
        addWhenfalse = true;
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(node_outputs_withoutDT,...
            nasa_toLustre.lustreAst.MergeBoolExpr(isEnabledVar, true_expr, addWhentrue, false_expr, addWhenfalse));
    end
    
end


function [body, variables_cell, pre_out_vars, InitialOutputs] = ...
        getPreOutputsCode(subsys, hasActionPort, hasEnablePort, forceToHeld, main_sampleTime)
    fields = fieldnames(subsys.Content);
    Outportfields = ...
        fields(cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
        && strcmp(subsys.Content.(x).BlockType, 'Outport')), fields));
    variables_cell = {};
    body = {};
    pre_out_vars = {};
    InitialOutputs = {};
    for i=1:numel(Outportfields)
        outport_blk = subsys.Content.(Outportfields{i});
        [outputs_i, outputs_DT_i] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(subsys, outport_blk, [], [], main_sampleTime);
        OutputWhenDisabled = outport_blk.OutputWhenDisabled;
        InitialOutput_cell =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(subsys, outport_blk,...
            outport_blk.InitialOutput, outport_blk.CompiledPortDataTypes.Inport{1}, outport_blk.CompiledPortWidths.Inport);
        for out_idx=1:numel(outputs_i)
            out_name = outputs_i{out_idx}.getId();
            pre_out_name = sprintf('pre_%s',out_name);
            variables_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(pre_out_name, ...
                outputs_DT_i{out_idx}.getDT());
            pre_out_vars{end+1} = nasa_toLustre.lustreAst.VarIdExpr(pre_out_name);
            InitialOutputs{end+1} = InitialOutput_cell{out_idx};
            if ~forceToHeld ...
                    && strcmp(OutputWhenDisabled, 'reset') ...
                    && (hasActionPort || hasEnablePort)
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(pre_out_name),...
                    InitialOutput_cell{out_idx});
            else
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                    nasa_toLustre.lustreAst.VarIdExpr(pre_out_name),...
                    nasa_toLustre.lustreAst.IteExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
                    nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()),...
                    nasa_toLustre.lustreAst.IntExpr(0)), ...
                    nasa_toLustre.lustreAst.UnaryExpr(...
                    nasa_toLustre.lustreAst.UnaryExpr.PRE, outputs_i{out_idx}), ...
                    InitialOutput_cell{out_idx}));
            end
        end
    end
end
