function [lustre_code, delay_node_code, variables, external_libraries] = ...
        get_code( parent, blk, lus_backend, InitialConditionSource, DelayLengthSource,...
        DelayLength, DelayLengthUpperLimit, ExternalReset, ShowEnablePort, xml_trace, main_sampleTime )
    
    % This function is called from Delay_To_Lustre and UnitDelay_To_Lustre,
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    %initialize outputs
    external_libraries = {};
    lustre_code = {};
    delay_node_code = {};
    [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
    
    variables = outputs_dt;
    
    
    
    widths = blk.CompiledPortWidths.Inport;
    nb_inports = numel(widths);
    inputs = cell(1, nb_inports);
    for i=1:nb_inports
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
    end
    
    % cast first input if needed to outputDataType
    % We cast only the U and X0 inports, X0 can be given from
    % outside. If it is the case, the X0 port number, by
    % convention From Simulink, is the last one.  lendth(widths)
    % gives the number of inports therefore the port number of X0.
    inportDataType = blk.CompiledPortDataTypes.Inport{1};
    lus_inportDataType_cell = cell(1, numel(outputs_dt));
    for i=1:numel(outputs_dt)
        lus_inportDataType_cell{i} = outputs_dt{i}.getDT();
    end
    if strcmp(InitialConditionSource, 'Input port')
        x0_U_Ports = [1, nb_inports];
        %x0DataType = blk.CompiledPortDataTypes.Inport{end};
    else
        [ICValue, ~, status] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.InitialCondition);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                blk.InitialCondition, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, 'Constant_To_Lustre', '');
            return;
        end
        if numel(ICValue) > 1
            if ~(strcmp(DelayLengthSource, 'Dialog') ...
                    && DelayLength == 1)
                display_msg(sprintf('InitialCondition %s in block %s is not supported for delay > 1',...
                    blk.InitialCondition, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
        end
        x0Port = numel(inputs) + 1;
        
        %inline ICValue
        if numel(ICValue) == 1 && numel(lus_inportDataType_cell) > 1
            ICValue = arrayfun(@(x) ICValue, (1:numel(lus_inportDataType_cell)));
        end
        
        %inline lus_inportDataType
        if numel(lus_inportDataType_cell) == 1 && numel(ICValue) > 1
            lus_inportDataType_cell = arrayfun(@(x) {lus_inportDataType_cell{1}}, (1:numel(ICValue)));
        end
        
        %x0DataType =  inportDataType;
        for i=1:numel(ICValue)
            inputs{x0Port}{i} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                ICValue(i), lus_inportDataType_cell{i});
        end
        
        x0_U_Ports = [1, (nb_inports+1)];
        widths(end+1) = numel(inputs{x0Port});
    end
    
    max_width = max(widths(x0_U_Ports));
    for i=x0_U_Ports
        if numel(inputs{i}) < max_width
            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
        end
    end
    
    
    if strcmp(DelayLengthSource, 'Dialog')
        delayLength = DelayLength;
        isDelayVariable = 0;
    else
        
        delayLength = DelayLengthUpperLimit;
        isDelayVariable = 1;
        delayDataType = blk.CompiledPortDataTypes.Inport{2};
        if ~MatlabUtils.contains(delayDataType, 'int')
            delayLengthDT = 'uint32';
            [external_lib, conv_format] = ...
                nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(delayDataType, delayLengthDT);
            if ~isempty(conv_format)
                external_libraries = [external_libraries, external_lib];
                inputs{2} = cellfun(@(x) ...
                    nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{2}, 'un', 0);
            end
        end
        
    end
    x0 =  inputs{end};
    u = inputs{1};
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    reset_var = '';
    isReset = ~strcmp(ExternalReset, 'None');
    codes = {};
    
    % Reset port
    if isReset
        isReset = 1;
        %detect the port number of reset port
        if strcmp(DelayLengthSource, 'Input port') ...
                && strcmp(ShowEnablePort, 'on')
            resetPort = 4;
        elseif ~(strcmp(DelayLengthSource, 'Input port') ...
                || strcmp(ShowEnablePort, 'on'))
            resetPort = 2;
        else
            resetPort = 3;
        end
        %construct reset condition
        resetportDataType = blk.CompiledPortDataTypes.Inport{resetPort};
        [resetDT, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(resetportDataType);
        resetValue = inputs{resetPort};
        
        [resetCode, status] =nasa_toLustre.utils.SLX2LusUtils.getResetCode( ...
            ExternalReset,resetDT, resetValue , zero);
        if status
            display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                ExternalReset, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, 'Constant_To_Lustre', '');
            return;
        end
        reset_var = sprintf('Reset_%s', blk_name);
        
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr(reset_var),...
            resetCode);
        if LusBackendType.isLUSTREC(lus_backend) ...
                || LusBackendType.isZUSTRE(lus_backend)
            variables{end + 1} = nasa_toLustre.lustreAst.LustreVar(reset_var, 'bool clock');
        else
            variables{end + 1} = nasa_toLustre.lustreAst.LustreVar(reset_var, 'bool');
        end
        
    end
    % Create enable condition
    isEnabe = strcmp(ShowEnablePort, 'on');
    if isEnabe
        %detect the port number of enable port
        if strcmp(DelayLengthSource, 'Dialog')
            enablePort = 2;
        else
            enablePort = 3;
        end
        
        %construct enabled condition
        enableportDataType = blk.CompiledPortDataTypes.Inport{enablePort};
        [~, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(enableportDataType);
        enableCondition = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.GT, inputs{enablePort}{1}, zero);
        
        enable_var = sprintf('isEnable_%s', blk_name);
        
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr(enable_var),...
            enableCondition);
        if LusBackendType.isLUSTREC(lus_backend) ...
                || LusBackendType.isZUSTRE(lus_backend)
            variables{end + 1} = nasa_toLustre.lustreAst.LustreVar(enable_var, 'bool clock');
        else
            variables{end + 1} = nasa_toLustre.lustreAst.LustreVar(enable_var, 'bool');
        end
    end
    pre_u = cell(1, numel(u));
    if isReset || isDelayVariable || isEnabe
        %if the input is a bus with different DataTypes, we need to
        %create an external node for each dataType
        if numel(unique(lus_inportDataType_cell)) == 1
            delay_node_name = sprintf('Delay_%s', blk_name);
            [delay_node_code] = ...
                nasa_toLustre.blocks.Delay_To_Lustre.getDelayNode(delay_node_name, ...
                lus_inportDataType_cell{1}, delayLength, isDelayVariable);
            isBus = false;
        else
            isBus = true;
            uniqueDT = unique(lus_inportDataType_cell);
            delay_node_code = {};
            for i=1:numel(uniqueDT)
                delay_node_name = sprintf('Delay_%s_%s', ...
                    blk_name, uniqueDT{i});
                [delay_node_code_i] = ...
                    nasa_toLustre.blocks.Delay_To_Lustre.getDelayNode(delay_node_name, ...
                    uniqueDT{i}, delayLength, isDelayVariable);
                delay_node_code{i} = delay_node_code_i;
            end
        end
        if isReset && LusBackendType.isJKIND(lus_backend)
            %Jkind does not have an operator to restart a node memory
            display_msg(sprintf(['Block "%s" is not supported by JKind model checker.', ...
                ' The block has a "reset" option when the Subsystem is reactivated. ', ...
                'This optiont is supported by the other model checks. ', ...
                cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
                HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, 'condExecSS_To_LusMerge', '');
            return;
        end
        
        for i=1:numel(u)
            args = {};
            if isBus
                delay_node_name = sprintf('Delay_%s_%s', ...
                    blk_name, lus_inportDataType_cell{i});
            end
            args{1} = u{i};
            args{2} = x0{i};
            if isDelayVariable
                args{end + 1} = inputs{2}{1};
            end
            original_node_call =  nasa_toLustre.lustreAst.NodeCallExpr(delay_node_name, args);
            if isEnabe
                
                if LusBackendType.isJKIND(lus_backend)
                    condact_args{1} = nasa_toLustre.lustreAst.VarIdExpr(enable_var);
                    condact_args{2} = original_node_call;
                    condact_args{3} = x0{i};
                    pre_u{i} = nasa_toLustre.lustreAst.CondactExpr(condact_args);
                    
                else
                    [ ~, zero ] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( outputs_dt{i}.getDT());
                    isEnabledVar = nasa_toLustre.lustreAst.VarIdExpr(enable_var);
                    if isReset
                        restart_cond = nasa_toLustre.lustreAst.VarIdExpr(reset_var);
                    else
                        restart_cond = {};
                    end
                    true_expr = nasa_toLustre.lustreAst.ActivateExpr(...
                        delay_node_name, args, ...
                        isEnabledVar, isReset, restart_cond);
                    addWhentrue = false;
                    false_expr = nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                        zero, ...
                        nasa_toLustre.lustreAst.UnaryExpr(...
                        nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                        outputs{i}));
                    addWhenfalse = true;
                    pre_u{i} =  nasa_toLustre.lustreAst.MergeBoolExpr(isEnabledVar, true_expr, addWhentrue, false_expr, addWhenfalse);
                end
                
                
            elseif isReset
                pre_u{i} = nasa_toLustre.lustreAst.EveryExpr(...
                    delay_node_name, ...
                    args, nasa_toLustre.lustreAst.VarIdExpr(reset_var));
            else
                pre_u{i} = original_node_call;
            end
        end
        
    else
        for i=1:numel(u)
            pre_u{i} =  nasa_toLustre.blocks.Delay_To_Lustre.getExpofNDelays(x0{i},...
                u{i}, delayLength);
        end
    end
    
    for i=1:numel(u)
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(outputs{i} , pre_u{i} );
    end
    lustre_code = codes;
    
end

