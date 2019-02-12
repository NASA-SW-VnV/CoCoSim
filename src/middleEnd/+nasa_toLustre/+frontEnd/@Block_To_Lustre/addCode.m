
function addCode(obj, code)
    if iscell(code)
        obj.lustre_code = [obj.lustre_code, code];
    elseif ~ischar(code) && numel(code) > 1
        for i=1:numel(code)
            obj.lustre_code{end +1} = code(i);
        end
    else
        obj.lustre_code{end +1} = code;
    end
end
