%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [Value, valueDataType, status] = evalParam(modelObj, parent, blk, param)
    % get the value of a parameter
    % This function should work with IR structure extracted from
    % the Simulink model and used in ToLustre compiler.
    % It can be used with char representing the PATH as well. We change them later
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
        if isnumeric(param) 
            % comes from a struct field
            Value = param;
        elseif isempty(regexp(param, '[a-zA-Z]', 'match'))
            % do not use str2double
            Value = str2num(param);
            if MatlabUtils.contains(param, '.')
                valueDataType = 'double';
            else
                valueDataType = 'int';
            end
        elseif strcmp(param, 'true') ...
                ||strcmp(param, 'false')
            Value = evalin('base', param);
            valueDataType = 'boolean';
        else
            try
                % if this is the case of variable from model workspace
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
                % if this is the case of variable from Mask Work space
                v = get_param(parent.Handle, 'MaskWSVariables');
                getMaskValue = containers.Map({v.Name}', {v.Value}');
                Value = getMaskValue(param);
                valueDataType =  class(Value);
                return;
            catch
                % It is not a Mask workspace variable
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
                % TODO fix bug here were a variable define in the script 
                % have the same name than one in the workspace
                Value = evalin('base', param);
                if ischar(Value)
                    [Value, valueDataType, status] = ...
                        SLXUtils.evalParam(modelObj, parent, blk, Value);
                    return;
                end
                valueDataType =  class(Value);
                
                if isstruct(Value)
                    fields = fieldnames(Value);
                    newValue = [];
                    for i=1:length(fields)
                        [Value_i, ~, status] = ...
                            SLXUtils.evalParam(modelObj, parent, blk, Value.(fields{i}));
                        if status
                            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                Value.(fields{i}), blk), ...
                                MsgType.ERROR, 'SLXUtils.evalParam', '');
                            return;
                        end
                        newValue = MatlabUtils.concat(newValue, double(Value_i));
                    end
                    Value = newValue;
                end
                
            catch me
                if strcmp(me.identifier, 'MATLAB:UndefinedFunction')
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
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'SLXUtils.evalParam', '');
        status = 1;
    end
end

