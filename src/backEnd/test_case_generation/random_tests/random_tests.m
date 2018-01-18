function [ T,  new_model_name] = random_tests( model_full_path, nb_steps, IMIN, IMAX, exportToWs, mkHarnessMdl )
%RANDOM_TESTS Summary of this function goes here
%   Detailed explanation goes here

if ~exist(model_full_path, 'file')
    display_msg(['File not foudn: ' model_full_path],...
        MsgType.ERROR, 'random_tests', '');
    return;
else
    model_full_path = which(model_full_path);
end
[model_path, slx_file_name, ~] = fileparts(model_full_path);
display_msg(['Generating random tests for : ' slx_file_name],...
    MsgType.INFO, 'random_tests', '');
if ~exist('nb_steps', 'var') || isempty(nb_steps)
    nb_steps = 100;
end
if ~exist('IMAX', 'var') || isempty(IMAX)
    IMAX = 100;
end
if ~exist('IMIN', 'var') || isempty(IMIN)
    IMIN = -100;
end
if ~exist('exportToWs', 'var') || isempty(exportToWs)
    exportToWs = 0;
end
if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
    mkHarnessMdl = 0;
end
addpath(model_path);
load_system(model_full_path);
%% Get model inports informations
[inports, inputEvents_names] = SLXUtils.get_model_inputs_info(model_full_path);
[T, ~, ~] = SLXUtils.get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN);
new_model_name = '';
if exportToWs
    assignin('base', strcat(slx_file_name, '_random_tests'), T);
    display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_random_tests')],...
        MsgType.RESULT, 'random_tests', '');
end

if mkHarnessMdl
    output_dir = fullfile(model_path, 'cocosim_output', slx_file_name);
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end
    new_model_name = SLXUtils.makeharness(T, slx_file_name, output_dir);
end
end

