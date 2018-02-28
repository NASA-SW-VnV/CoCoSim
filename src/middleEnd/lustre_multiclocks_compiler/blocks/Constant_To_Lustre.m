classdef Constant_To_Lustre < Block_To_Lustre
    %Test_write a dummy class
    
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            obj.addVariable(outputs_dt);
            lus_outputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            if isempty(regexp(blk.Value, '[a-zA-Z]', 'match'))
                Value = str2num(blk.Value);
                if contains(blk.Value, '.')
                    valueDataType = 'double';
                else
                    valueDataType = 'int';
                end
            elseif strcmp(blk.Value, 'true') ...
                    ||strcmp(blk.Value, 'false')
                Value = evalin('base', blk.Value);
                valueDataType = 'boolean';
            else
                try
                    Value = evalin('base', blk.Value);
                    valueDataType =  evalin('base',...
                        sprintf('class(%s)', blk.Value));
                catch
                    % search the variable in Model workspace, if not raise
                    % unsupported option
                    model_name = regexp('Constant/Constant1', filesep, 'split');
                    model_name = model_name{1};
                    hws = get_param(model_name, 'modelworkspace') ;
                    if hasVariable(hws, blk.Value)
                        Value = getVariable(hws, blk.Value);
                    else
                        obj.addUnsupported_options(...
                            sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                            blk.Value, blk.Origin_path));
                    end
                end
            end
            [value_inlined, status, msg] = MatlabUtils.inline_values(Value);
            if status
                obj.addUnsupported_options(msg);
                return;
            end
            values_str = {};
            for i=1:numel(value_inlined)
                if strcmp(lus_outputDataType, 'real')
                    values_str{i} = sprintf('%.15f', value_inlined(i));
                    valueDataType = 'double';
                elseif strcmp(lus_outputDataType, 'int')
                    values_str{i} = sprintf('%d', int32(value_inlined(i)));
                    valueDataType = 'int';
                elseif strncmp(valueDataType, 'int', 3) ...
                        || strncmp(valueDataType, 'uint', 4)
                    values_str{i} = num2str(value_inlined(i));
                elseif strcmp(valueDataType, 'boolean') || strcmp(valueDataType, 'logical')
                    if value_inlined(i)
                        values_str{i} = 'true';
                    else
                        values_str{i} = 'false';
                    end
                else
                    values_str{i} = sprintf('%.15f', value_inlined(i));
                end
            end
            
            
            for j=1:numel(outputs)
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, values_str{j});
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
    
end

