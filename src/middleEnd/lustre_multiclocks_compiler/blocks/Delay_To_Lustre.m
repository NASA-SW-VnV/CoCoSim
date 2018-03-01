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
        
        function  write_code(obj, parent, blk, varargin)
            [lustre_code, variables, external_libraries, unsupported_options] = ...
                Delay_To_Lustre.get_code( parent, blk, ...
                blk.InitialConditionSource, blk.DelayLengthSource,...
                blk.DelayLength, blk.ExternalReset, blk.ShowEnablePort );
            obj.addVariable(variables);
            obj.addExternal_libraries(external_libraries);
            obj.addUnsupported_options(unsupported_options);
            obj.setCode(lustre_code);
            
            
        end
        
        function options = getUnsupportedOptions(obj,blk, varargin)
            InitialCondition = str2num(blk.InitialCondition);
            if numel(InitialCondition) > 1
                obj.addUnsupported_options(...
                    sprintf('InitialCondition condition %s is not supported in block %s.', ...
                    num2str(InitialCondition), blk.Origin_path));
            end
            if ~strcmp(DelayLengthSource, 'Dialog')
                obj.addUnsupported_options(...
                    sprintf('DelayLengthSource is external and not supported in block %s.', ...
                    blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
    methods(Static = true)
        function [lustre_code, variables, external_libraries, unsupported_options] = ...
                get_code( parent, blk, InitialConditionSource, DelayLengthSource,...
                DelayLength, ExternalReset, ShowEnablePort )
            %initialize outputs
            external_libraries = {};
            unsupported_options = {};
            lustre_code = '';
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            variables = outputs_dt;
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
            nb_inports = numel(widths);
            
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
            if strcmp(InitialConditionSource, 'Input port')
                I = [1, nb_inports];
                x0DataType = blk.CompiledPortDataTypes.Inport{end};
            else
                
                if isempty(regexp(blk.InitialCondition, '[a-zA-Z]', 'match'))
                    InitialCondition = str2num(blk.InitialCondition);
                    if contains(blk.InitialCondition, '.')
                        x0DataType = 'double';
                    else
                        x0DataType = 'int';
                    end
                elseif strcmp(blk.InitialCondition, 'true') ...
                        ||strcmp(blk.InitialCondition, 'false')
                    InitialCondition = evalin('base', blk.InitialCondition);
                    x0DataType = 'boolean';
                else
                    try
                        InitialCondition = evalin('base', blk.InitialCondition);
                        x0DataType =  evalin('base',...
                            sprintf('class(%s)', blk.InitialCondition));
                    catch
                        % search the variable in Model workspace, if not raise
                        % unsupported option
                        model_name = regexp(blk.Origin_path, filesep, 'split');
                        model_name = model_name{1};
                        hws = get_param(model_name, 'modelworkspace') ;
                        if hasVariable(hws, blk.InitialCondition)
                            InitialCondition = getVariable(hws, blk.InitialCondition);
                            x0DataType = 'double';
                        else
                            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                blk.InitialCondition, blk.Origin_path), ...
                                MsgType.ERROR, 'Constant_To_Lustr', '');
                            return;
                        end
                    end
                end
                if numel(InitialCondition) > 1
                    [value_inlined, status, msg] = MatlabUtils.inline_values(InitialCondition);
                    if status
                        %message
                        display_msg(msg, MsgType.ERROR, 'Constant_To_Lustr', '');
                        return;
                    end
                    for i=1:numel(value_inlined)
                        if strcmp(lus_inportDataType, 'real')
                            InitialCondition = sprintf('%.15f', value_inlined(i));
                            x0DataType = 'double';
                        elseif strcmp(lus_inportDataType, 'int')
                            InitialCondition = sprintf('%d', int32(value_inlined(i)));
                            x0DataType = 'int';
                        elseif strncmp(x0DataType, 'int', 3) ...
                                || strncmp(x0DataType, 'uint', 4)
                            InitialCondition = num2str(value_inlined(i));
                        elseif strcmp(x0DataType, 'boolean') || strcmp(x0DataType, 'logical')
                            if value_inlined(i)
                                InitialCondition = 'true';
                            else
                                InitialCondition = 'false';
                            end
                        else
                            InitialCondition = sprintf('%.15f', value_inlined(i));
                        end
                        inputs{end+1}{i} = InitialCondition;
                    end
                else
                    if strcmp(lus_inportDataType, 'real')
                        InitialCondition = sprintf('%.15f', InitialCondition);
                        x0DataType = 'double';
                    elseif strcmp(lus_inportDataType, 'int')
                        InitialCondition = sprintf('%d', int32(InitialCondition));
                        x0DataType = 'int';
                    elseif strncmp(x0DataType, 'int', 3) ...
                            || strncmp(x0DataType, 'uint', 4)
                        InitialCondition = num2str(InitialCondition);
                    elseif strcmp(x0DataType, 'boolean') || strcmp(x0DataType, 'logical')
                        if InitialCondition
                            InitialCondition = 'true';
                        else
                            InitialCondition = 'false';
                        end
                    else
                        InitialCondition = sprintf('%.15f', InitialCondition);
                    end
                    inputs{end+1} = {InitialCondition};
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
                    external_libraries = external_lib;
                    inputs{end} = cellfun(@(x) sprintf(conv_format,x), inputs{end}, 'un', 0);
                end
            end
            if strcmp(DelayLengthSource, 'Dialog')
                delay = str2num(DelayLength);
            else
                display_msg(sprintf('DelayLengthSource is external and not supported in block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Delay_To_Lustre', '');
                return;
            end
            x0 =  inputs{end};
            u = inputs{1};
            blk_name = SLX2LusUtils.name_format(blk.Name);
            reset_cond = arrayfun(@(x) {''}, (1:numel(u)));
            codes = {};
            % Reset port
            if ~strcmp(ExternalReset, 'None')
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
                reset_var = sprintf('Reset_%s', blk_name);
                variables{numel(variables) + 1} = sprintf ('%s:bool;',...
                    reset_var);
                codes{numel(codes) + 1} = sprintf('%s = %s;\n\t'...
                    ,reset_var , Delay_To_Lustre.getResetCode(...
                    ExternalReset,resetDT, char(resetValue) , zero));
                for i=1:numel(u)
                    reset_cond{i} = sprintf(' if %s then %s else \n\t\t'...
                        ,reset_var , x0{i});
                end
            end
            %enable port
            if strcmp(ShowEnablePort, 'on')
                
                %detect the port number of enable port
                if strcmp(DelayLengthSource, 'Dialog')
                    enablePort = 2;
                else
                    enablePort = 3;
                end
                
                %construct enabled condition
                enableportDataType = blk.CompiledPortDataTypes.Inport{enablePort};
                [~, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                enableCondition = sprintf('%s > %s', inputs{enablePort}{1}, zero);
                % construct additional variables
                for i=1:numel(u)
                    varName = sprintf('%s_%s', u{i}, blk_name);
                    variables{numel(variables) + 1} = ...
                        sprintf ('%s:%s;',...
                        varName, SLX2LusUtils.get_lustre_dt(inportDataType));
                    pre_u =  Delay_To_Lustre.getExpofNDelays(...
                        x0{i}, varName, delay);
                    codes{numel(codes) + 1} = sprintf(...
                        '%s = if  (%s) then %s\n\t\t\t', ...
                        varName, enableCondition, u{i} );
                    codes{numel(codes) + 1} = sprintf(...
                        'else %s -> pre %s;\n\t', x0{i}, varName);
                    codes{numel(codes) + 1} = sprintf(...
                        '%s =  if (%s) then \n\t\t\t %s %s\n\t\t\t', ...
                        outputs{i}, enableCondition,reset_cond{i}, pre_u );
                    codes{numel(codes) + 1} = sprintf(...
                        'else 0.0 -> pre %s;\n\t', outputs{i});
                end
                
            else
                for i=1:numel(u)
                    pre_u =  Delay_To_Lustre.getExpofNDelays(x0{i},...
                        u{i}, delay);
                    codes{numel(codes) + 1} = sprintf('%s = %s %s;\n\t',...
                        outputs{i} , reset_cond{i},  pre_u );
                end
            end
            lustre_code = MatlabUtils.strjoin(codes, '');
            
        end
        
        function [resetCode, unsupported_options] = getResetCode(resetType,resetDT, resetInput, zero )
            unsupported_options = {};
            if strcmp(resetDT, 'bool')
                b = sprintf('%s',resetInput);
            else
                b = sprintf('(%s >= %s)',resetInput , zero);
            end
            if strcmp(resetType, 'Rising')
                resetCode = sprintf(...
                    '%s and not pre %s'...
                    ,b ,b );
            elseif strcmp(resetType, 'Falling')
                resetCode = sprintf(...
                    'not %s and pre %s'...
                    ,b ,b);
            elseif strcmp(resetType, 'Either')
                resetCode = sprintf(...
                    '(%s and not pre %s) or (not %s and pre %s) '...
                    ,b ,b ,b ,b);
            else
                unsupported_options{numel(unsupported_options) + 1} = ...
                    sprintf('This External reset type [%s] is not supported in block %s.', ...
                    resetType, blk.Origin_path);
                return;
            end
        end
        
        function code = getExpofNDelays(x0, u, D)
            if D == 0
                code = sprintf(' %s ' , u);
            else
                code = sprintf(' %s -> pre(%s) ', x0 , Delay_To_Lustre.getExpofNDelays(x0, u, D -1));
            end
            
        end
    end
    
end

