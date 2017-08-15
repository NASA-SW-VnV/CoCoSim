%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Configure Verification menue: the menu and functions callbacks
%
[validation_root, ~, ~] = fileparts(mfilename('fullpath'));
verification_items{1} = fullfile(validation_root, 'lustreValidate', 'lusValidateMenu.m');
verification_items{2} = fullfile(validation_root, 'cocoSpecValidate', 'cocoSpecVerifyMenu.m');