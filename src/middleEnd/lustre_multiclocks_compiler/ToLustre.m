function [nom_lustre_file, xml_trace]= ToLustre(model_path, const_files, mode_display, varargin)
%lustre_multiclocks_compiler translate Simulink models to Lustre. It is based on
%article :
%INPUTS:
%   MODEL_PATH: The full path of the Simulink model.
%   CONST_FILES: The list of constant files to be run in order to be able
%   to simulate the simulink model.
%   MODE_DISPLAY: equals to 0 if no display wanted, equals to 1 if the user
%   want the Simulink model to be open.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% inputs treatment
if nargin < 1
    display_help_message();
    return;
end
if ~exist('const_files', 'var') || isempty(const_files)
    const_files = {};
end
if ~exist('mode_display', 'var') || isempty(mode_display)
    mode_display = 0;
end



%% initialize outputs
nom_lustre_file = '';

%% Get start time
t_start = tic;

%% Get Simulink model full path
if (exist(model_path, 'file') == 2 || exist(model_path, 'file') == 4)
    model_full_path = model_path;
else
    model_full_path = which(model_path);
end
%% Save current path
PWD = pwd;

%% Run constants
SLXUtils.run_constants_files(const_files);


%% Pre-process model
display_msg('Pre-processing', MsgType.INFO, 'lustre_multiclocks_compiler', '');
% if nargin > 3
%     varargin = [varargin; {'nodisplay'}];
% else
%     varargin = 'nodisplay';
% end
[new_file_name, status] = cocosim_pp(model_full_path ,'nodisplay',  varargin{:});
if status
    return;
end
%% Update model path with the pre-processed model
if ~strcmp(new_file_name, '')
    model_full_path = new_file_name;
    [model_dir, file_name, ~] = fileparts(model_full_path);
    if mode_display == 1
        open(model_full_path);
    end
else
    display_msg('Pre-processing has failed', MsgType.ERROR, 'lustre_multiclocks_compiler', '');
    return;
end

%% Definition of the generated output files names
output_dir = fullfile(model_dir, 'cocosim_output', file_name);
nom_lustre_file = fullfile(output_dir, strcat(file_name, '.lus'));
if ~exist(output_dir, 'dir'); mkdir(output_dir); end

%% Create Meta informations
create_file_meta_info(nom_lustre_file);

%% Create traceability informations in XML format
display_msg('Start tracebility', MsgType.INFO, 'lustre_multiclocks_compiler', '');
trace_file_name = fullfile(output_dir, strcat(file_name, '.cocosim2.trace.xml'));
xml_trace = XML_Trace(model_full_path, trace_file_name);
xml_trace.init();


%% Internal representation building %%%%%%
display_msg('Building internal format', MsgType.INFO, 'lustre_multiclocks_compiler', '');
[ir_struct, ~, ~, ~] = cocosim_IR(model_full_path, 0, output_dir);
% Pre-process IR
[ir_struct] = internalRep_pp(ir_struct, 1, output_dir);


%% Lustre generation
display_msg('Lustre generation', Constants.INFO, 'lustre_multiclocks_compiler', '');


main_block = ir_struct.(IRUtils.name_format(file_name));
main_sampleTime = main_block.CompiledSampleTime;

[nodes_code, external_libraries] = recursiveGeneration(main_block, main_sampleTime, xml_trace);
external_lib_code = getExternalLibrariesNodes(external_libraries);
%% writing code
fid = fopen(nom_lustre_file, 'a');
if fid==-1
    msg = sprintf('Opening file "%s" is not possible', nom_lustre_file);
    display_msg(msg, MsgType.ERROR, 'lustre_multiclocks_compiler', '');
end
fprintf(fid, '--external libraries\n%s--Simulink code\n%s',external_lib_code, nodes_code);
fclose(fid);

%% display report files
t_finish = toc(t_start);
msg = sprintf('Lustre generation finished in %f seconds', t_finish);
display_msg(nodes_code, MsgType.DEBUG, 'lustre_multiclocks_compiler', '');
display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');
cd(PWD)
end

%%
function [nodes_code, external_libraries] = recursiveGeneration(blk, main_sampleTime, xml_trace)
nodes_code = '';
external_libraries = {};
if isfield(blk, 'Content')
    field_names = fieldnames(blk.Content);
    for i=1:numel(field_names)
        [nodes_code_i, external_libraries_i] = recursiveGeneration(blk.Content.(field_names{i}), main_sampleTime, xml_trace);
        if ~isempty(nodes_code_i)
            nodes_code = sprintf('%s\n%s', nodes_code_i, nodes_code);
        end
        external_libraries = [external_libraries, external_libraries_i];
    end
    [main_node, external_nodes, external_libraries_i] = subsystem2node(blk, main_sampleTime, xml_trace);
    external_libraries = [external_libraries, external_libraries_i];
    nodes_code = sprintf('%s\n%s\n%s', external_nodes, nodes_code, main_node);
    
end
end

%%
function display_help_message()
msg = ' -----------------------------------------------------  \n';
msg = [msg '  CoCoSim: Automated Analysis Framework for Simulink/Stateflow\n'];
msg = [msg '   \n Usage:\n'];
msg = [msg '    >> cocoSim(MODEL_PATH, {MAT_CONSTANTS_FILES})\n'];
msg = [msg '\n'];
msg = [msg '      MODEL_PATH: a string containing the full/relative path to the model\n'];
msg = [msg '        e.g. cocoSim(''test/properties/safe_1.mdl'')\n'];
msg = [msg '      MAT_CONSTANT_FILES: an optional list of strings containing the\n'];
msg = [msg '      path to the mat files containing the simulation constants\n'];
msg = [msg '        e.g. {''../../constants1.mat'',''../../constants2.mat''}\n'];
msg = [msg '        default: {}\n'];
msg = [msg  '  -----------------------------------------------------  \n'];
cprintf('blue', msg);
end

%%
function create_file_meta_info(lustre_file)
% Create lustre file
fid = fopen(lustre_file, 'w');
text = '-- This file has been generated by CoCoSim2.\n\n';
text = [text, '-- Compiler: Lustre compiler 2 (ToLustre.m)\n'];
text = [text, '-- Time: ', char(datetime), '\n'];
fprintf(fid, text);
fclose(fid);
end

