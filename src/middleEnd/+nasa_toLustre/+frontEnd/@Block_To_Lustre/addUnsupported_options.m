
function addUnsupported_options(obj, option)
    if iscell(option)
        obj.unsupported_options = [obj.unsupported_options, option];
    else
        obj.unsupported_options{numel(obj.unsupported_options) +1} = option;
    end
end
