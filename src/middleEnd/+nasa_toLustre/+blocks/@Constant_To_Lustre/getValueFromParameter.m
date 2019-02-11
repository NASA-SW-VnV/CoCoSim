
function [Value, valueDataType, status] = ...
        getValueFromParameter(parent, blk, param)
    model_name = regexp(blk.Origin_path, filesep, 'split');
    model_name = model_name{1};
    [Value, valueDataType, status] = ...
        SLXUtils.evalParam(model_name, parent, blk, param);
end
