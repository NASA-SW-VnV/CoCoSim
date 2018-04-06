%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = generateInvariantsMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'View generated CoCoSpec (Experimental)';
schema.statustip = 'Generate the invariants used for safe properties';
schema.autoDisableWhen = 'Busy';

generateInvariants_config;
schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, menu_items,...
                    'UniformOutput', false);
end
