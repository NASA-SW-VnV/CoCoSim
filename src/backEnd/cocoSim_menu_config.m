%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   In this configuration file the user can add a menu to CoCoSim toolbar.
%   he needs to follow the same template defined in the following example.
%   Variables:
%   menue_items: Cell array containing the path to CoCoSim Menu items.

%% Configure CoCoSim toolbar: the menu and functions callbacks
%
%take the current file directory.
[src_root, ~, ~] = fileparts(mfilename('fullpath'));
menue_items = {};
menue_items{numel(menue_items) + 1} = fullfile(src_root, 'verification','verificationMenu.m');
menue_items{numel(menue_items) + 1} = fullfile(src_root, 'test_case_generation','TestCaseGenMenu.m');
menue_items{numel(menue_items) + 1} = fullfile(src_root, 'generate_invariants','generateInvariantsMenu.m');
menue_items{numel(menue_items) + 1} = fullfile(src_root, 'generate_code','generateCodeMenu.m');
menue_items{numel(menue_items) + 1} = fullfile(src_root, 'validation','validationMenu.m');

