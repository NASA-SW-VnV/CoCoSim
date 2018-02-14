function [ T,  new_model_name] = mcdc_tests( model_full_path,...
    exportToWs, mkHarnessMdl )
%mcdc_tests Summary of this function goes here
%   Detailed explanation goes here

if ~exist(model_full_path, 'file')
    display_msg(['File not foudn: ' model_full_path],...
        MsgType.ERROR, 'mutation_tests', '');
    return;
else
    model_full_path = which(model_full_path);
end
[model_path, slx_file_name, ~] = fileparts(model_full_path);
display_msg(['Generating mc-dc coverage tests for : ' slx_file_name],...
    MsgType.INFO, 'mutation_tests', '');

if ~exist('exportToWs', 'var') || isempty(exportToWs)
    exportToWs = 0;
end
if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
    mkHarnessMdl = 0;
end
addpath(model_path);
load_system(model_full_path);
%% Compile model
lus_full_path = lustre_compiler(model_full_path);
[output_dir, lus_file_name, ~] = fileparts(lus_full_path);
[ T] = lustret_test_mcdc( lus_full_path, lus_file_name,  output_dir);

%%
if exportToWs
    assignin('base', strcat(slx_file_name, '_mcdc_tests'), T);
    display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_mcdc_tests')],...
        MsgType.RESULT, 'mutation_tests', '');
end

%%
new_model_name = '';
if mkHarnessMdl
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end
    new_model_name = SLXUtils.makeharness(T, slx_file_name, output_dir);
end
end

