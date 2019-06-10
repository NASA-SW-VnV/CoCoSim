function sl_customization( cm )
%sl_customization Register custom menu function.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cm.addCustomMenuFcn('Simulink:ToolsMenu', @(x) {@cocosim_menu.tools_menu});
cm.addCustomMenuFcn('Simulink:PreContextMenu',@(x) {@cocosim_menu.precontext_menu});
end