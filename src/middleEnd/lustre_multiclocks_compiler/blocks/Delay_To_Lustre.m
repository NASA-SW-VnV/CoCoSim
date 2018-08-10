classdef Delay_To_Lustre < Block_To_Lustre
    %Delay_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [lustre_code, delay_node_code, variables, external_libraries] = ...
                Delay_To_Lustre.get_code( parent, blk, ...
                blk.InitialConditionSource, blk.DelayLengthSource,...
                blk.DelayLength, blk.DelayLengthUpperLimit, blk.ExternalReset, blk.ShowEnablePort, xml_trace );
            obj.addVariable(variables);
            obj.addExternal_libraries(external_libraries);
            obj.addExtenal_node(delay_node_code);
            obj.setCode(lustre_code);
            
            
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            
            if isempty(regexp(blk.InitialCondition, '[a-zA-Z]', 'match'))
                InitialCondition = str2num(blk.InitialCondition);
            elseif strcmp(blk.InitialCondition, 'true') ...
                    ||strcmp(blk.InitialCondition, 'false')
                InitialCondition = evalin('base', blk.InitialCondition);
            else
                try
                    InitialCondition = evalin('base', blk.InitialCondition);
                catch
                    % search the variable in Model workspace, if not raise
                    % unsupported option
                    model_name = regexp(blk.Origin_path, filesep, 'split');
                    model_name = model_name{1};
                    hws = get_param(model_name, 'modelworkspace') ;
                    if hasVariable(hws, blk.InitialCondition)
                        InitialCondition = getVariable(hws, blk.InitialCondition);
                    else
                        obj.addUnsupported_options(...
                            sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                            blk.InitialCondition, blk.Origin_path));
                        return;
                    end
                end
            end
            if numel(InitialCondition) > 1 ...
                    && ~(strcmp(DelayLengthSource, 'Dialog') ...
                    && strcmp(DelayLength, '1'))
                obj.addUnsupported_options(...
                    sprintf('InitialCondition %s in block %s is not supported for delay > 1',...
                    blk.InitialCondition, blk.Origin_path));
            end
            
            options = obj.unsupported_options;
        end
    end
    
    methods(Static = true)
        function [lustre_code, delay_node_code, variables, external_libraries] = ...
                get_code( parent, blk, InitialConditionSource, DelayLengthSource,...
                DelayLength, DelayLengthUpperLimit, ExternalReset, ShowEnablePort, xml_trace )
            %initialize outputs
            external_libraries = {};
            lustre_code = {};
            delay_node_code = {};
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);

            variables = outputs_dt;
            
            
            
            widths = blk.CompiledPortWidths.Inport;
            nb_inports = numel(widths);
            inputs = cell(1, nb_inports);
            for i=1:nb_inports
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            end
            
            % cast first input if needed to outputDataType
            % We cast only the U and X0 inports, X0 can be given from
            % outside. If it is the case, the X0 port number, by
            % convention From Simulink, is the last one.  numel(widths)
            % gives the number of inports therefore the port number of X0.
            inportDataType = blk.CompiledPortDataTypes.Inport{1};
            [lus_inportDataType, ~] = SLX2LusUtils.get_lustre_dt(inportDataType);
            if ischar(lus_inportDataType)
                %change it to cell array
                lus_inportDataType_cell{1} = lus_inportDataType;
            else
                lus_inportDataType_cell = lus_inportDataType;
            end
            if strcmp(InitialConditionSource, 'Input port')
                I = [1, nb_inports];
                x0DataType = blk.CompiledPortDataTypes.Inport{end};
            else
                [ICValue, x0DataType, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, blk.InitialCondition);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.InitialCondition, blk.Origin_path), ...
                        MsgType.ERROR, 'Constant_To_Lustre', '');
                    return;
                end
                if numel(ICValue) > 1
                    if ~(strcmp(DelayLengthSource, 'Dialog') ...
                            && strcmp(DelayLength, '1'))
                        display_msg(sprintf('InitialCondition %s in block %s is not supported for delay > 1',...
                            blk.InitialCondition, blk.Origin_path), ...
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
                if strcmp(lus_inportDataType_cell{1}, 'real')
                    x0DataType = 'double';
                elseif strcmp(lus_inportDataType_cell{1}, 'int')
                    x0DataType = 'int';
                elseif strcmp(lus_inportDataType_cell{1}, 'bool')
                    x0DataType = 'boolean';
                end
                for i=1:numel(ICValue)
                    inputs{x0Port}{i} = SLX2LusUtils.num2LusExp(...
                        ICValue(i), lus_inportDataType_cell{i}, x0DataType);
                end
                
                I = [1, (nb_inports+1)];
                widths(end+1) = 1;
            end
            max_width = max(widths(I));
            for i=I
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
            end
            
            %converts the x0 data type(s) to the first inport data type
            %(Simulink documentation)
            if ~strcmp(x0DataType, inportDataType)
                [external_lib, conv_format] = ...
                    SLX2LusUtils.dataType_conversion(x0DataType, inportDataType);
                if ~isempty(external_lib)
                    external_libraries = [external_libraries, external_lib];
                    inputs{end} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{end}, 'un', 0);
                end
            end
            if strcmp(DelayLengthSource, 'Dialog')
                delayLength = str2double(DelayLength);
                isDelayVariable = 0;
            else
                
                delayLength = str2double(DelayLengthUpperLimit);
                isDelayVariable = 1;
                delayDataType = blk.CompiledPortDataTypes.Inport{2};
                if delayLength <= 255
                    delayLengthDT = 'uint8';
                else
                    delayLengthDT = 'uint16';
                end
                [external_lib, conv_format] = ...
                    SLX2LusUtils.dataType_conversion(delayDataType, delayLengthDT);
                if ~isempty(external_lib)
                    external_libraries = [external_libraries, external_lib];
                    inputs{2} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        inputs{2}, 'un', 0);
                end
            end
            x0 =  inputs{end};
            u = inputs{1};
            blk_name = SLX2LusUtils.node_name_format(blk);
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
                [resetDT, zero] = SLX2LusUtils.get_lustre_dt(resetportDataType);
                resetValue = inputs{resetPort};
                
                [resetCode, status] = SLX2LusUtils.getResetCode( ...
                    ExternalReset,resetDT, resetValue , zero);
                if status
                    display_msg(sprintf('This External reset type [%s] is not supported in block %s.', ...
                    ExternalReset, blk.Origin_path), ...
                        MsgType.ERROR, 'Constant_To_Lustre', '');
                    return;
                end
                reset_var = sprintf('Reset_%s', blk_name);

                codes{end + 1} = LustreEq(VarIdExpr(reset_var),...
                    resetCode);
                variables{end + 1} = LustreVar(reset_var, 'bool');
                
            end
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
                [~, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                enableCondition = BinaryExpr(BinaryExpr.GT, ...
                    inputs{enablePort}{1}, zero);
                %sprintf('(%s > %s)', inputs{enablePort}{1}, zero);
                % construct additional variables
                for i=1:numel(u)
                    varName = sprintf('%s_%s', u{i}.getId(), blk_name);
                    dt = SLX2LusUtils.get_lustre_dt(inportDataType);
                    lhs = VarIdExpr(varName);
                    variables{end + 1} = LustreVar(varName, dt);
                    codes{end + 1} = LustreEq(lhs, ...
                        IteExpr(enableCondition, ...
                        VarIdExpr(u{i}), ...
                        BinaryExpr(BinaryExpr.ARROW, ...
                                    x0{i}, ...
                                    UnaryExpr(UnaryExpr.PRE, VarIdExpr(varName)))));
                    %codes{end + 1} = sprintf(...
                    %    '%s = if  %s then %s\n\t\t\t', ...
                    %    lhs, enableCondition, u{i} );
                    %codes{end + 1} = sprintf(...
                    %    'else %s -> pre %s;\n\t', x0{i}, varName);
                    u{i} = VarIdExpr(varName);
                end
            end
            pre_u = cell(1, numel(u));
            if isReset || isDelayVariable || isEnabe
                %if the input is a bus with different DataTypes, we need to
                %create an external node for each dataType
                if numel(unique(lus_inportDataType_cell)) == 1
                    delay_node_name = sprintf('Delay_%s', blk_name);
                    [delay_node_code] = ...
                        Delay_To_Lustre.getDelayNode(delay_node_name, ...
                        lus_inportDataType_cell{1}, delayLength,...
                        isDelayVariable, isReset, isEnabe);
                    isBus = false;
                else
                    isBus = true;
                    uniqueDT = unique(lus_inportDataType_cell);
                    delay_node_code = {};
                    for i=1:numel(uniqueDT)
                        delay_node_name = sprintf('Delay_%s_%s', ...
                            blk_name, uniqueDT{i});
                        [delay_node_code_i] = ...
                            Delay_To_Lustre.getDelayNode(delay_node_name, ...
                            uniqueDT{i}, delayLength,...
                            isDelayVariable, isReset, isEnabe);
                        delay_node_code{i} = delay_node_code_i;
                    end
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
                    if isReset
                        args{end + 1} = VarIdExpr(reset_var);
                    end
                    if isEnabe
                        args{end + 1} = enableCondition;
                    end
                    pre_u{i} = NodeCallExpr(delay_node_name, args);
                    %sprintf('%s)',node_call_format);
                end
            else
                for i=1:numel(u)
                    pre_u{i} =  Delay_To_Lustre.getExpofNDelays(x0{i},...
                        u{i}, delayLength);
                end
            end
            
            for i=1:numel(u)
                codes{end + 1} = LustreEq(outputs{i} , pre_u{i} );
            end
            lustre_code = codes;
            
        end
        
        function [delay_node] = getDelayNode(node_name, ...
                u_DT, delayLength, isDelayVariable, isReset, isEnabel)
            %node header
            [ u_DT, zero ] = SLX2LusUtils.get_lustre_dt( u_DT);
            node_inputs{1} = LustreVar('u', u_DT);
            node_inputs{2} = LustreVar('x0', u_DT);
            if isDelayVariable
                node_inputs{end + 1} = LustreVar('d', 'int');
            end
            if isReset
                node_inputs{end + 1} = LustreVar('reset', 'bool');
            end
            if isEnabel
                node_inputs{end + 1} = LustreVar('enable', 'bool');
            end
           
            
            pre_u_conds = {};
            pre_u_thens = {};
            if isDelayVariable
                pre_u_conds{end + 1} = BinaryExpr(BinaryExpr.LT, ...
                    VarIdExpr('d'), IntExpr(1));
                pre_u_thens{end + 1} = VarIdExpr('u');
                pre_u_conds{end + 1} = BinaryExpr(BinaryExpr.GT, ...
                    VarIdExpr('d'), IntExpr(delayLength));
                pre_u_thens{end + 1} = VarIdExpr('pre_u1');
            end
            variables = cell(1, delayLength);
            body = cell(1, delayLength + 1 );
            for i=1:delayLength
                pre_u_i = sprintf('pre_u%d', i);
                if i< delayLength
                    pre_u_i_plus_1 = sprintf('pre_u%d', i+1);
                else
                    pre_u_i_plus_1 = 'u';
                end
                if isReset
                    enable_then = IteExpr(...
                        VarIdExpr('reset'), ...
                        VarIdExpr('x0'),...
                        UnaryExpr(UnaryExpr.PRE, ...
                                    VarIdExpr(pre_u_i_plus_1)));
                else
                    enable_then = UnaryExpr(UnaryExpr.PRE, ...
                        VarIdExpr(pre_u_i_plus_1));
                end
                if isEnabel
                    enable_else = BinaryExpr(...
                        BinaryExpr.ARROW, ...
                        zero, ...
                        UnaryExpr(UnaryExpr.PRE, ...
                            VarIdExpr(pre_u_i)));
                    enable = IteExpr(VarIdExpr('enable'), enable_then, enable_else);
                else
                    enable = enable_then;
                end
                rhs = BinaryExpr(...
                        BinaryExpr.ARROW, ...
                        VarIdExpr('x0'), ...
                        enable);
                body{i} = LustreEq(VarIdExpr(pre_u_i), rhs);
                
                if isDelayVariable
                    j = delayLength - i + 1;
                    pre_u_conds{end + 1} = BinaryExpr(BinaryExpr.EQ, ...
                        VarIdExpr('d'), IntExpr(i));
                    pre_u_thens{end+1} = VarIdExpr(sprintf('pre_u%d', j));
                    %pre_u = sprintf('%s if d = %d then pre_u%d\n\t\telse', ...
                    %    pre_u, i, j);
                end
                variables{i} = LustreVar(pre_u_i, u_DT);
            end
            if isDelayVariable
                pre_u_thens{end+1} = VarIdExpr('x0');
            else
                pre_u_thens{end+1} = VarIdExpr('pre_u1');
            end
            pre_u_rhs = IteExpr.nestedIteExpr(pre_u_conds, pre_u_thens);
            if isEnabel
                pre_u_rhs = IteExpr(...
                    VarIdExpr('enable'), ...
                    pre_u_rhs, ...
                    BinaryExpr(...
                        BinaryExpr.ARROW, ...
                        zero, ...
                        UnaryExpr(UnaryExpr.PRE, ...
                            VarIdExpr('pre_u'))));
            end
            pre_u = LustreEq(VarIdExpr('pre_u'), pre_u_rhs);
            body{delayLength + 1} = pre_u;
            outputs = LustreVar('pre_u', u_DT);
            delay_node = LustreNode({},...
                node_name, node_inputs, outputs, ...
                {}, variables, body, false);
            %node_header = sprintf('node %s(%s)\nreturns(pre_u:%s);\n',...
            %    node_name, node_inputs, u_DT);
            %sprintf('%s%slet\n\t%s%s\ntel',...
            %    node_header, vars, body, pre_u);
        end
        
        
        
        function code = getExpofNDelays(x0, u, d)
            if d == 0
                code = u;
                %sprintf(' %s ' , u);
            else
                code = BinaryExpr(BinaryExpr.ARROW, ...
                    x0, ...
                    UnaryExpr(UnaryExpr.PRE, ...
                        Delay_To_Lustre.getExpofNDelays(x0, u, d - 1)));
                %sprintf(' %s -> pre(%s) ', x0 , Delay_To_Lustre.getExpofNDelays(x0, u, D -1));
            end
            
        end
    end
    
end

