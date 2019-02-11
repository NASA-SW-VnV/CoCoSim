
function addExternal_libraries(obj, lib)
    if isempty(lib)
        return;
    elseif iscell(lib)
        obj.external_libraries = [obj.external_libraries, lib];
    elseif ~ischar(lib) && numel(lib) > 1
        for i=1:numel(lib)
            obj.external_libraries{end +1} = lib(i);
        end
    else
        obj.external_libraries{end +1} = lib;
    end
end
