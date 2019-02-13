%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setName(obj, name)
    obj.name = name;
    % check the object is a valid Lustre AST.
    if ~ischar(name)
        ME = MException('COCOSIM:LUSTREAST', ...
            'LustreNode ERROR: Expected parameter name of type char got "%s".',...
            class(name));
        throw(ME);
    end
end
