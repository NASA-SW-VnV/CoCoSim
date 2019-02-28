%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for compatibility with old cocosim libraries, we add this global
% variable.
global cocosim_config_already_run;
if isempty(cocosim_config_already_run)
    cocosim_config_already_run = false;
end
if cocosim_config_already_run
    % only tools_config is needed from old compiler
    tools_config;
else
    %% add paths
    [cocoSim_root, ~, ~] = fileparts(mfilename('fullpath'));
    warning off
    %add all folders except tools sub-folders
    addpath(genpath(cocoSim_root)); 
    rmpath(genpath(fullfile(cocoSim_root, 'tools')));
    %add only tools not its sub-folders
    addpath(fullfile(cocoSim_root, 'tools'));
    % addpath(genpath(fullfile(cocoSim_root, 'libs')));
    % addpath(genpath(fullfile(cocoSim_root, 'scripts')));
    % addpath(genpath(fullfile(cocoSim_root, 'src')));
    % addpath(fullfile(cocoSim_root, 'tools'));
    
    %% First configuration, Zustre, Kind2 and Lustrec
    % Go to tools/tools_config and follow instructions
    install_cocosim_lib();
    tools_config;
    
    
    %% Second configuration Pre-processing
    % Go to src/pp/pp_config and follow instructions
    pp_config;
    fprintf('\n\t Click <a href="matlab: pp_user_config">here</a> to change pre-processing configuration.\n');
    
    %% IR config
    
    ir_utils_path = fullfile(cocoSim_root, 'src', 'frontEnd', 'IR', 'utils');
    json_encode_file = 'json_encode';
    json_decode_file = 'json_decode';
    
    if ismac
        json_encode_file = fullfile(ir_utils_path, 'json_encode.mexmaci64');
        json_decode_file = fullfile(ir_utils_path, 'json_decode.mexmaci64');
    elseif isunix
        json_encode_file = fullfile(ir_utils_path, 'json_encode.mexa64');
        json_decode_file = fullfile(ir_utils_path, 'json_decode.mexa64');
    elseif ispc
        json_encode_file = fullfile(ir_utils_path, 'json_encode.mexw64');
        json_decode_file = fullfile(ir_utils_path, 'json_decode.mexw64');
    end
    
    if ~ exist(json_encode_file, 'file') || ~ exist(json_decode_file, 'file')
        if exist(fullfile(ir_utils_path, 'make.m'), 'file')
            PWD = pwd;
            cd(ir_utils_path);
            try
                make
            catch  ME
                display_msg(ME.getReport(), MsgType.ERROR, 'cocosim_config', '');
            end
            cd(PWD);
        end
    end
    
    %% Java external libraries
    matlabParser = fullfile(cocoSim_root, 'src','frontEnd', 'IR',...
        'Matlab_IR', 'Matlab-Parser.jar');
    
    if exist(matlabParser, 'file')
        javaaddpath(matlabParser);
    end
    
    warning on
    cocosim_config_already_run = true;
end