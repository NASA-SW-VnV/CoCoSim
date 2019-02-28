%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [stateEnumType, childAst] = ...
        addStateEnum(state, child, isInner, isJunction, inactive)
    global SF_STATES_ENUMS_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    stateEnumType = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateEnumType(state);
    state_name = upper(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state));
    if nargin >= 3 && isInner
        childName = strcat(state_name, '_InnerTransition');
    elseif nargin >= 4 && isJunction
        childName = strcat(state_name, '_StoppedInJunction');
    elseif nargin == 5 && inactive
        childName = strcat(state_name, '_INACTIVE');
    elseif ischar(child)
        %child is given using nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName
        childName = upper(child);
    else
        childName = upper(...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(child));
    end
    if ~isKey(SF_STATES_ENUMS_MAP, stateEnumType)
        SF_STATES_ENUMS_MAP(stateEnumType) = {childName};
    elseif ~ismember(childName, SF_STATES_ENUMS_MAP(stateEnumType))
        SF_STATES_ENUMS_MAP(stateEnumType) = [...
            SF_STATES_ENUMS_MAP(stateEnumType), childName];
    end
    childAst = nasa_toLustre.lustreAst.EnumValueExpr(childName);
end
