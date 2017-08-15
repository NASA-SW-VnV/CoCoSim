function schema = cocoSim_menu(callbackInfo)
%cocoSim_menu Define the custom menu function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

schema = sl_container_schema;
schema.label = 'CoCoSim';
schema.statustip = 'Automated Analysis Framework';
schema.autoDisableWhen = 'Busy';

cocoSim_menu_config;
schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, menue_items,...
                    'UniformOutput', false);

end

