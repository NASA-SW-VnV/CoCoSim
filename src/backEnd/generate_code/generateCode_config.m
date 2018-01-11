%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   In this configuration file the user can add an item to Generation
%   menu. 
%   the user needs to follow the same template defined in the following example.
%   Variables:
%   menu_items: Cell array containing the path to Verification Menu items.

%% Configure Verification menue: the menu and functions callbacks
%
%take the current file directory.
[gen_root, ~, ~] = fileparts(mfilename('fullpath'));
menu_items{1} = fullfile(gen_root, 'C', 'CMenu.m');
menu_items{2} = fullfile(gen_root, 'Lustre', 'LustreMenu.m');
menu_items{3} = fullfile(gen_root, 'Rust', 'RustMenu.m');
