classdef Constant_To_Lustre < Block_To_Lustre
    %Constant_To_Lustre
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            obj.addVariable(outputs_dt);
            lus_outputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            [Value, valueDataType, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Value);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Value, blk.Origin_path), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            
            values_str = {};
            width = numel(Value);
            for i=1:width
                if strcmp(lus_outputDataType, 'real')
                    values_str{i} = sprintf('%.15f', Value(i));
                elseif strcmp(lus_outputDataType, 'int')
                    values_str{i} = sprintf('%d', int32(Value(i)));
                elseif strcmp(lus_outputDataType, 'bool')
                    if Value(i)
                        values_str{i} = 'true';
                    else
                        values_str{i} = 'false';
                    end
                elseif strncmp(valueDataType, 'int', 3) ...
                        || strncmp(valueDataType, 'uint', 4)
                    values_str{i} = num2str(Value(i));
                elseif strcmp(valueDataType, 'boolean') || strcmp(valueDataType, 'logical')
                    if Value(i)
                        values_str{i} = 'true';
                    else
                        values_str{i} = 'false';
                    end
                else
                    values_str{i} = sprintf('%.15f', Value(i));
                end
            end
            
            
            for j=1:numel(outputs)
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, values_str{j});
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % search the variable in Model workspace, if not raise
            % unsupported option
            if isvarname(blk.Value)
                try
                    evalin('base', blk.Value);
                catch
                    model_name = regexp(blk.Origin_path, filesep, 'split');
                    model_name = model_name{1};
                    hws = get_param(model_name, 'modelworkspace') ;
                    if ~hasVariable(hws, blk.Value)
                        obj.addUnsupported_options(...
                            sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                            blk.Value, blk.Origin_path));
                    end
                end
            end
            options = obj.unsupported_options;
        end
    end
    methods(Static = true)
        function [Value, valueDataType, status] = ...
                getValueFromParameter(parent, blk, param)
            status = 0;
            valueDataType = 'double';
            if isempty(regexp(param, '[a-zA-Z]', 'match'))
                Value = str2num(param);
                if contains(param, '.')
                    valueDataType = 'double';
                else
                    valueDataType = 'int';
                end
            elseif strcmp(param, 'true') ...
                    ||strcmp(param, 'false')
                Value = evalin('base', param);
                valueDataType = 'boolean';
            else
                
                % search the variable in Model workspace, if not raise
                % unsupported option
                model_name = regexp(blk.Origin_path, filesep, 'split');
                model_name = model_name{1};
                hws = get_param(model_name, 'modelworkspace') ;
                if isvarname(param) && hasVariable(hws, param)
                    Value = getVariable(hws, param);
                else
                    try
                        Value = evalin('base', param);
                        valueDataType =  evalin('base',...
                            sprintf('class(%s)', param));
                    catch
                        try
                            Value = get_param(parent.Origin_path, param);
                            Value = evalin('base', Value);
                        catch
                            status = 1;
                        end
                    end
                end
            end
        end
    end
    
    
end

