%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   In this configuration file the user can add an item to Validation
%   menu. 
%   the user needs to follow the same template defined in the following example.
%   Variables:
%   Validation_items: Cell array containing the path to Validation Menu items.

%% Configure Validation menue: the menu and functions callbacks
%
[validation_root, ~, ~] = fileparts(mfilename('fullpath'));
validation_items{1} = fullfile(validation_root, 'lustreValidate', 'lusValidateMenu.m');
validation_items{2} = fullfile(validation_root, 'cocoSpecValidate', 'cocoSpecValidateMenu.m');