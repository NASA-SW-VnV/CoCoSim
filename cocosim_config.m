%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% add paths
[cocoSim_root, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(cocoSim_root, 'libs')));
addpath(genpath(fullfile(cocoSim_root, 'src')));
addpath(fullfile(cocoSim_root, 'tools'));



%% First configuration, Zustre, Kind2 and Lustrec
% Go to tools/tools_config and follow instructions
tools_config;


%% Second configuration Pre-processing
% Go to src/pp/pp_config and follow instructions
pp_config;
fprintf('\n\t Click <a href="matlab: pp_user_config">here</a> to open pre-processing configuration.\n');

%% IR config
if exist(fullfile(cocoSim_root, 'src', 'frontend', 'IR', 'std_IR', 'utils', 'make.m'), 'file')
    PWD = pwd;
    cd(fullfile(cocoSim_root, 'src', 'frontend', 'IR', 'std_IR', 'utils'));
    try
        make
    catch
    end
    cd(PWD);
end