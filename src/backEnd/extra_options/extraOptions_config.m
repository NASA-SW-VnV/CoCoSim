%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   In this configuration file the user can add an item to Extra options
%   menu. 
%   the user needs to follow the same template defined in the following example.
%   Variables:
%   options_items: Cell array containing the path to Extra options Menu items.

%% Configure Validation menue: the menu and functions callbacks
%
function options_items = extraOptions_config()

[validation_root, ~, ~] = fileparts(mfilename('fullpath'));
options_items{1} = fullfile(validation_root, 'pp', 'ppMenu.m');
options_items{2} = fullfile(validation_root, 'IR', 'IRMenu.m');
end