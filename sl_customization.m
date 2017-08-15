function sl_customization( cm )
%sl_customization Register custom menu function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cm.addCustomMenuFcn('Simulink:ToolsMenu', @getMyMenuItems);

end

%% Define the custom menu function.
function schemaFcns = getMyMenuItems
cocoSim_menu_handle = str2func('cocoSim_menu');
schemaFcns = {cocoSim_menu_handle};
end