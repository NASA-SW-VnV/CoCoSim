%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   In this configuration file the user can add an item to Verification
%   menu. 
%   the user needs to follow the same template defined in the following example.
%   Variables:
%   verification_items: Cell array containing the path to Verification Menu items.

%% Configure Verification menue: the menu and functions callbacks
%
%take the current file directory.
[verif_root, ~, ~] = fileparts(mfilename('fullpath'));
verification_items{1} = fullfile(verif_root, 'lustreVerify', 'lusVerifyMenu.m');
verification_items{2} = fullfile(verif_root, 'cocoSpecVerify', 'cocoSpecVerifyMenu.m');