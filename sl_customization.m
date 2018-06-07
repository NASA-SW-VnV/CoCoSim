%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sl_customization( cm )
%sl_customization Register custom menu function.
cm.addCustomMenuFcn('Simulink:ToolsMenu', @getMyMenuItems);
cm.addCustomMenuFcn('Simulink:PreContextMenu', @PreContextMenu.preContextMenu);
end

%% Define the custom menu function.
function schemaFcns = getMyMenuItems
cocosim_menu_path = fullfile(fileparts(mfilename('fullpath')),...
    'src', 'backEnd', 'cocoSim_menu.m');
cocoSim_menu_handle = MenuUtils.funPath2Handle(cocosim_menu_path);
schemaFcns = {cocoSim_menu_handle};
end