classdef UnitDelay_To_Lustre < Block_To_Lustre
    %Test_write a dummy class
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            obj.variables = outputs_dt;
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
            if isempty(regexp(blk.InitialCondition, '[a-zA-Z]', 'match'))
                x0_condition = str2num(blk.InitialCondition);
                if contains(blk.InitialCondition, '.')
                    x0DataType = 'double';
                elseif strcmp(inportDataType, 'double')
                    x0_condition = sprintf('%f', x0_condition);
                    x0DataType = 'double';
                else
                    x0DataType = 'int';
                end
            elseif strcmp(blk.InitialCondition, 'true') ...
                    ||strcmp(blk.InitialCondition, 'false')
                x0_condition = evalin('base', blk.InitialCondition);
                x0DataType = 'boolean';
            else
                % the case of parameters from the workspace
                x0_condition = evalin('base', blk.InitialCondition);
                x0DataType =  evalin('base',...
                    sprintf('class(%s)', blk.InitialCondition));
            end
            if numel(x0_condition) > 1
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('InitialCondition condition %s is not supported in block %s.', ...
                    num2str(x0_condition), blk.Origin_path);
                return;
            else
                if strncmp(x0DataType, 'int', 3) ...
                        || strncmp(x0DataType, 'uint', 4)
                    x0_condition = num2str(x0_condition);
                elseif strcmp(x0DataType, 'boolean') || strcmp(x0DataType, 'logical')
                    if x0_condition
                        x0_condition = 'true';
                    else
                        x0_condition = 'false';
                    end
                else
                    x0_condition = sprintf('%.15f', x0_condition);
                end
            end
            
            
            
            %converts the x0 data type(s) to the first inport data type
            %(Simulink documentation)
            if ~strcmp(x0DataType, inportDataType)
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(x0DataType, inportDataType);
                if ~isempty(external_lib)
                    obj.external_libraries = [obj.external_libraries,...
                        external_lib];
                    x0_condition = sprintf(conv_format, x0_condition);
                end
            end
            
            u = inputs{1};
            
            codes = {};
            for j=1:numel(u)
                code =  sprintf(' %s -> pre(%s) ', x0_condition , u{j});
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, code);
            end
            
            obj.code = MatlabUtils.strjoin(codes, '');
            
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
    
    
end

