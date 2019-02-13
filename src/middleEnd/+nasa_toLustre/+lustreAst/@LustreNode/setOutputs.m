%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setOutputs(obj, outputs)
    if ~iscell(outputs) && numel(outputs) == 1
        obj.outputs{1} = outputs;
    else
        obj.outputs = outputs;
    end
    outputsClass = unique(...
        cellfun(@(x) class(x), obj.outputs, 'UniformOutput', 0));
    if ~isempty(obj.outputs) && ~(numel(outputsClass) == 1 ...
            && isequal(outputsClass{1}, 'nasa_toLustre.lustreAst.LustreVar'))
        ME = MException('COCOSIM:LUSTREAST', ...
            'LustreNode ERROR: Expected outputs of type LustreVar got types "%s".',...
            MatlabUtils.strjoin(outputsClass, ', '));
        throw(ME);
    end
end        
