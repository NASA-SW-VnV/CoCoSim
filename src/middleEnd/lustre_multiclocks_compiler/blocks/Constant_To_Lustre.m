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
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
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
            
            
            width = numel(Value);
            values_AST = cell(1, width);
            for i=1:width
                values_AST{i} = SLX2LusUtils.num2LusExp(Value(i),...
                    lus_outputDataType, valueDataType);
            end
            
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                codes{j} = LustreEq(outputs{j}, values_AST{j});
            end
            
            obj.setCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj,~, blk, varargin)
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

