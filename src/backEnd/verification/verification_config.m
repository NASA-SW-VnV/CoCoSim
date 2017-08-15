%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Configure Verification menue: the menu and functions callbacks
%
[verif_root, ~, ~] = fileparts(mfilename('fullpath'));
verification_items{1} = fullfile(verif_root, 'lustreVerify', 'lusVerifyMenu.m');
verification_items{2} = fullfile(verif_root, 'cocoSpecVerify', 'cocoSpecVerifyMenu.m');