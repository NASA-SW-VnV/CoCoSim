
%% get the value of a parameter
function [Value, valueDataType, status] = evalParam(modelObj, parent, blk, param)
% This function should work with IR structure extracted from
% the Simulink model and used in ToLustre compiler.
% It can be used with char parameters as well. We change them
% to objects
    status = 0;
    valueDataType = 'double';
    Value = 0;
    try
        if ~isempty(modelObj) && ischar(modelObj)
            modelObj = get_param(modelObj, 'Object');
        end
        if ischar(parent)
            parent = get_param(parent, 'Object');
        end
        if ischar(blk)
            blk = get_param(blk, 'Object');
        end
        if isempty(regexp(param, '[a-zA-Z]', 'match'))
            % do not use str2double
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
            % this is the case of variable from model workspace
            try
                hws = modelObj.ModelWorkspace ;
                if isvarname(param) && hasVariable(hws, param)
                    Value = getVariable(hws, param);
                    valueDataType =  class(Value);
                    return;
                end
            catch
                % It is not a variable from model workspace
            end
            try
                try
                    %if it is not a mask parameter, it will
                    %launch an exception.
                    new_param = parent.(param);
                    new_parent = get_param(parent.Handle, 'Parent');
                    [Value, valueDataType, status] = ...
                        SLXUtils.evalParam(...
                        modelObj, ...
                        new_parent, ...
                        parent,...
                        new_param);
                    if status
                        display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                            new_param, parent), ...
                            MsgType.ERROR, 'SLXUtils.evalParam', '');
                        return;
                    end
                    return;
                catch
                    % It is not a mask parameter
                end
                Value = evalin('base', param);
                if ischar(Value)
                    [Value, valueDataType, status] = ...
                        SLXUtils.evalParam(modelObj, parent, blk, Value);
                    return;
                end
                valueDataType =  class(Value);
            catch me
                if isequal(me.identifier, 'MATLAB:UndefinedFunction')
                    % Case of e.g. param = 2*f and f is a mask parameter
                    tokens = ...
                        regexp(me.message, '''(\w+)''', 'tokens', 'once');
                    if ~isempty(tokens)
                        f = tokens{1};
                        try
                            %if it is not a mask parameter, it will
                            %launch an exception.
                            new_param = parent.(f);
                            new_parent = get_param(parent.Handle, 'Parent');
                            [f_v, ~, status] = ...
                                SLXUtils.evalParam(...
                                modelObj, ...
                                new_parent, ...
                                parent,...
                                new_param);
                            if status
                                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                    new_param, parent), ...
                                    MsgType.ERROR, 'SLXUtils.evalParam', '');
                                return;
                            end
                            % back to the complex param
                            assignin('base', f, f_v);
                            [Value, valueDataType, status] = ...
                                SLXUtils.evalParam(modelObj, parent, blk, param);
                            evalin('base', sprintf('clear %s', f));
                            return;
                        catch
                        end
                    end
                end
                try
                    Value = get_param(parent.Handle, param);
                    Value = evalin('base', Value);
                catch
                    status = 1;
                end
            end

        end
    catch
        status = 1;
    end
end

