%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GUIDELINES_CONFIG  This is a configuration file for CoCoSim GUIDELINES. You
%   will be able to choose what you want to be checked or to create
%   your own guidelines library. 
%
%   The standard guidelines has been pulled from Orion GN&C MATAB/Simulink
%   Standards
%   https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/solutions/aerospace-defense/standards/FltDyn-CEV-08-148_MATLAB_Standards_v9_20111202.pdf

%% get script path
config_path = fileparts(mfilename('fullpath'));

%% TODO: add your library path or leave it use the default one.
% the default one is "main", change "main" to your library name that is under
% src/pp
addpath(genpath(fullfile(config_path, 'main')));

%% TODO: Go to 'main/pp_order.m' to configure functions orders.
if exist(fullfile(config_path, 'main/guidelines_order.m'), 'file')
    guidelines_order;
end



