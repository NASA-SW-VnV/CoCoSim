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
            slx_dt = blk.CompiledPortDataTypes.Outport{1};
            lus_outputDataType = SLX2LusUtils.get_lustre_dt(slx_dt);
            [Value, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Value);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Value, blk.Origin_path), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            %inline value
            max_width = blk.CompiledPortWidths.Outport;
            if numel(Value) < max_width
                Value = arrayfun(@(x) Value(1), (1:max_width));
            end
            
            width = numel(Value);
            values_AST = cell(1, width);
            for i=1:width
                values_AST{i} = SLX2LusUtils.num2LusExp(Value(i),...
                    lus_outputDataType, slx_dt);
            end
            
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                codes{j} = LustreEq(outputs{j}, values_AST{j});
            end

                
            obj.setCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % search the variable in Model workspace, if not raise
            % unsupported option
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Value);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Value, blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static = true)
        function [Value, valueDataType, status] = ...
                getValueFromParameter(parent, blk, param)
            status = 0;
            valueDataType = 'double';
            Value = 0;
            if isempty(regexp(param, '[a-zA-Z]', 'match'))
                Value = str2num(param);% do not use str2double
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
                        if isfield(parent, param)
                            % mask parameter
                            [Value, valueDataType, status] = ...
                                Constant_To_Lustre.getValueFromParameter(...
                                parent, ...
                                parent,...
                                parent.(param));
                            return;
                        end    
                        Value = evalin('base', param);
                        if ischar(Value)
                            [Value, valueDataType, status] = ...
                                        Constant_To_Lustre.getValueFromParameter(parent, blk, Value);
                            return;
                        end
                        valueDataType =  class(Value);
                    catch me
                        if isequal(me.identifier, 'MATLAB:UndefinedFunction')
                            % check if it's a mask parameter
                            tokens = ...
                                regexp(me.message, '''(\w+)''', 'tokens', 'once');
                            if ~isempty(tokens)
                                f = tokens{1};
                                if isfield(parent, f)
                                    %it is a mask parameter
                                    [f_v, ~, ~] = ...
                                        Constant_To_Lustre.getValueFromParameter(parent, parent, parent.(f));
                                    assignin('base', f, f_v);
                                    [Value, valueDataType, status] = ...
                                        Constant_To_Lustre.getValueFromParameter(parent, blk, param);
                                    return;
                                end
                            end
                        end
                        try
                            Value = get_param(parent.Origin_path, param);
                            Value = evalin('base', Value);
                        catch me
                            status = 1;
                        end
                    end
                end
            end
        end
    end
    
    
end

