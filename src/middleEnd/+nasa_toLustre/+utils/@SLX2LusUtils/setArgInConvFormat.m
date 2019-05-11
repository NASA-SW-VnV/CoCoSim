%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Data type conversion node name
function new_callObj = setArgInConvFormat(callObj, arg)
    % this function goes with dataType_conversion funciton to set
    % the missing argument in conv_format.
    %
    %
    if isempty(callObj)
        new_callObj = arg;
        return;
    end
    new_callObj = callObj.deepCopy();
    args = new_callObj.getArgs();
    if iscell(args) && numel(args) == 1
        new_args = args{1};
    else
        new_args = args;
        
    end
    if isempty(new_args)
        new_callObj.setArgs(arg);
    elseif isa(new_args, 'nasa_toLustre.lustreAst.NodeCallExpr')
        new_callObj.setArgs(...
            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(new_args, arg));
    end
end
