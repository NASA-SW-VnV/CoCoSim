classdef Delay_To_Lustre < Block_To_Lustre
    %Test_write a dummy class
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            obj.addVariable(outputs_dt);
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
            
            if strcmp(blk.InitialConditionSource, 'Input port')
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
                    InitialCondition = evalin('base', blk.InitialCondition);
                    x0DataType =  evalin('base',...
                        sprintf('class(%s)', blk.InitialCondition));
                end
                if numel(InitialCondition) > 1
                    obj.addUnsupported_options(unsupported_options) = ...
                        sprintf('InitialCondition condition %s is not supported in block %s.', ...
                        num2str(InitialCondition), blk.Origin_path);
                    return;
                else
                    if strncmp(x0DataType, 'int', 3)
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
                end
                inputs{end+1} = {InitialCondition};
                
                I = [1, (nb_inports+1)];
                widths(end+1) = 1;
            end
            max_width = max(widths(I));
            for i=I
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
            end
            inportDataType = blk.CompiledPortDataTypes.Inport{1};
            
            %converts the x0 data type(s) to the first inport data type
            %(Simulink documentation)
            if ~strcmp(x0DataType, inportDataType)
                [external_lib, conv_format] = ...
                    SLX2LusUtils.dataType_conversion(x0DataType, inportDataType);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_libraries) = external_lib;
                    inputs{end} = cellfun(@(x) sprintf(conv_format,x), inputs{end}, 'un', 0);
                end
            end
            if strcmp(blk.DelayLengthSource, 'Dialog')
                delay = str2num(blk.DelayLength);
            else
                obj.addUnsupported_options(unsupported_options) = ...
                    sprintf('DelayLengthSource is external and not supported in block %s.', ...
                    blk.Origin_path);
                return;
            end
            x0 =  inputs{end};
            u = inputs{1};
            % trigger port
            
            %enable port
            if strcmp(blk.ShowEnablePort, 'on')
                
                %detect the port number of enable port
                if strcmp(blk.DelayLengthSource, 'Dialog')
                    enablePort = 2;
                else
                    enablePort = 3;
                end
                
                %construct enabled condition
                enableportDataType = blk.CompiledPortDataTypes.Inport{enablePort};
                [~, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                enableCondition = sprintf('%s > %s', inputs{enablePort}{1}, zero);
                % construct additional variables
                blk_name = SLX2LusUtils.name_format(blk.Name);
                codes = {};
                for i=1:numel(u)
                    varName = sprintf('%s_%s', u{i}, blk_name);
                    obj.addVariable(sprintf ('%s:%s;', varName, ...
                        SLX2LusUtils.get_lustre_dt(inportDataType) ));
                    pre_u =  Delay_To_Lustre.getExpofNDelays(...
                        x0{i}, varName, delay);
                    codes{numel(codes) + 1} = sprintf(...
                        '%s = if  (%s) then %s\n\t\t\t', ...
                        varName, enableCondition, u{i} );
                    codes{numel(codes) + 1} = sprintf(...
                        'else %s -> pre %s;\n\t', x0{i}, varName);
                    codes{numel(codes) + 1} = sprintf(...
                        '%s =  if (%s) then %s\n\t\t\t', ...
                        outputs{i} , enableCondition, pre_u );
                    codes{numel(codes) + 1} = sprintf(...
                        'else %s -> pre %s;\n\t', x0{i}, outputs{i});
                end
                
            else
                codes = {};
                for i=1:numel(u)
                    pre_u =  Delay_To_Lustre.getExpofNDelays(x0{i},...
                        u{i}, delay);
                    codes{i} = sprintf('%s = %s;\n\t',...
                        outputs{i} , pre_u );
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
    methods(Static = true)
        function code = getExpofNDelays(x0, u, D)
            if D == 0
                code = sprintf(' %s ' , u);
            else
                code = sprintf(' %s -> pre(%s) ', x0 , Delay_To_Lustre.getExpofNDelays(x0, u, D -1));
            end
            
        end
    end
    
end

