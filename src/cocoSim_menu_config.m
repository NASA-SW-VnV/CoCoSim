%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Configure CoCoSim toolbar: the menu and functions callbacks
%
[src_root, ~, ~] = fileparts(mfilename('fullpath'));
menue_items = {};
menue_items{numel(menue_items) + 1} = fullfile(src_root,'backend', 'verification','verificationMenu.m');
menue_items{numel(menue_items) + 1} = fullfile(src_root,'backend', 'validation','validationMenu.m');
