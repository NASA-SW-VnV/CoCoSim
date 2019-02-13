%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setInputs(obj, inputs)
    if ~iscell(inputs) && numel(inputs) == 1
        obj.inputs{1} = inputs;
    else
        obj.inputs = inputs;
    end
    inputsClass = unique(...
        cellfun(@(x) class(x), obj.inputs, 'UniformOutput', 0));
    if ~isempty(obj.inputs) && ~(numel(inputsClass) == 1 ...
            && isequal(inputsClass{1}, 'nasa_toLustre.lustreAst.LustreVar'))
        ME = MException('COCOSIM:LUSTREAST', ...
            'LustreNode ERROR: Expected inputs of type LustreVar got types "%s".',...
            MatlabUtils.strjoin(inputsClass, ', '));
        throw(ME);
    end
end
