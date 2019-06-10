
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function is_parent = isParent(Parent,child)

    if isempty(child)
        is_parent = true;
        return;
    end
    if ischar(child)
        childPath = child;
    elseif isfield(child, 'Path')
        childPath = child.Path;
    else
        %in destination struct, Name refers to Path. IR problem
        childPath = child.Name;
    end
    if ischar(Parent)
        ParentPath = Parent;
    elseif isfield(Parent, 'Path')
        ParentPath = Parent.Path;
    else
        %in destination struct, Name refers to Path. IR problem
        ParentPath = Parent.Name;
    end
    is_parent = MatlabUtils.startsWith(childPath, ParentPath);
end
