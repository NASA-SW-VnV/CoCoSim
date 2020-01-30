function addExternal_libraries(obj, lib)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
