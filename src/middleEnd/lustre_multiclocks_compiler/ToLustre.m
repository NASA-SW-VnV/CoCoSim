function [nom_lustre_file, xml_trace]= ToLustre(model_path, const_files, backend, varargin)
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

mode_display = 1;
for i=1:numel(varargin)
    if strcmp(varargin{i}, 'nodisplay')
        mode_display = 0;
    end
end
if ~exist('backend', 'var') || isempty(backend)
    backend = BackendType.LUSTREC; 
end

%% initialize outputs
nom_lustre_file = '';
xml_trace = [];
%% Get start time
t_start = tic;

%% Get Simulink model full path
if (exist(model_path, 'file') == 2 || exist(model_path, 'file') == 4)
    model_full_path = model_path;
else
    model_full_path = which(model_path);
end
if ~exist(model_full_path, 'file')
    error('Model "%s" Does not exist', model_path);
    
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
varargin{end+1} = 'use_backup';
[new_file_name, status] = cocosim_pp(model_full_path , varargin{:});
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
xml_trace_file_name = fullfile(output_dir, strcat(file_name, '.toLustre.trace.xml'));
json_trace_file_name = fullfile(output_dir, strcat(file_name, '_mapping.json'));
xml_trace = SLX2Lus_Trace(model_full_path,...
    xml_trace_file_name, json_trace_file_name);


%% Internal representation building %%%%%%

display_msg('Building internal format', MsgType.INFO, 'lustre_multiclocks_compiler', '');
[ir_struct, ~, ~, ~] = cocosim_IR(model_full_path, 0, output_dir);
% Pre-process IR
[ir_struct] = internalRep_pp(ir_struct, 1, output_dir);


%% Lustre generation
display_msg('Lustre generation', Constants.INFO, 'lustre_multiclocks_compiler', '');

global model_struct
model_struct = ir_struct.(IRUtils.name_format(file_name));
main_sampleTime = model_struct.CompiledSampleTime;
is_main_node = 1;
[nodes_ast, contracts_ast, external_libraries] = recursiveGeneration(...
    model_struct, model_struct, main_sampleTime, is_main_node, backend, xml_trace);
[external_lib_code, open_list] = getExternalLibrariesNodes(external_libraries, backend);
%TODO: change it to AST
nodes_ast = [external_lib_code, nodes_ast];
%% create LustreProgram
program =  LustreProgram(open_list, nodes_ast, contracts_ast);

% copy Kind2 libraries
if BackendType.isKIND2(backend) 
    if ismember('lustrec_math', open_list)
        lib_path = fullfile(fileparts(mfilename('fullpath')),...
            'lib', 'lustrec_math.lus');
        copyfile(lib_path, output_dir);
    end
end
%% writing code
fid = fopen(nom_lustre_file, 'a');
if fid==-1
    msg = sprintf('Opening file "%s" is not possible', nom_lustre_file);
    display_msg(msg, MsgType.ERROR, 'lustre_multiclocks_compiler', '');
end
Lustrecode = program.print(backend);
fprintf(fid, '%s', Lustrecode);
fclose(fid);

%% writing traceability
xml_trace.write();

%% display report files
t_finish = toc(t_start);
display_msg(Lustrecode, MsgType.DEBUG, 'lustre_multiclocks_compiler', '');
msg = sprintf('Lustre File generated:%s', nom_lustre_file);
display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');
msg = sprintf('Lustre generation finished in %f seconds', t_finish);
display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');
cd(PWD)
end

%%
function [nodes_ast, contracts_ast, external_libraries] = recursiveGeneration(parent, blk, main_sampleTime, is_main_node, backend, xml_trace)
nodes_ast = {};
contracts_ast = {};
external_libraries = {};

if isfield(blk, 'Content') && ~isempty(blk.Content)
    field_names = fieldnames(blk.Content);
    for i=1:numel(field_names)
        [nodes_code_i, contracts_ast_i, external_libraries_i] = recursiveGeneration(blk, blk.Content.(field_names{i}), main_sampleTime, 0, backend, xml_trace);
        if ~isempty(nodes_code_i)
            nodes_ast = [ nodes_ast, nodes_code_i];
        end
        if ~isempty(contracts_ast_i)
            contracts_ast{end + 1} = contracts_ast_i;
        end
        external_libraries = [external_libraries, external_libraries_i];
    end
    [b, status] = getWriteType(blk);
    if status || ~b.isContentNeedToBeTranslated()
        return;
    end
    [main_node, is_contract, external_nodes, external_libraries_i] = SS_To_LustreNode.subsystem2node(parent, blk, main_sampleTime, is_main_node, backend, xml_trace);
    external_libraries = [external_libraries, external_libraries_i];
    if iscell(external_nodes)
        nodes_ast = [ nodes_ast, external_nodes];
    else
        nodes_ast{end + 1} = external_nodes;
    end
    if is_contract && ~isempty(main_node)
        contracts_ast{end + 1} = main_node;
    elseif ~isempty(main_node)
        nodes_ast{end + 1} = main_node;
    end    
elseif isfield(blk, 'SFBlockType') && isequal(blk.SFBlockType, 'Chart')
    % Stateflow chart example
    [main_node, ~, external_nodes, external_libraries_i] = SS_To_LustreNode.subsystem2node(parent, blk, main_sampleTime, is_main_node, backend, xml_trace);
    external_libraries = [external_libraries, external_libraries_i];
    if iscell(external_nodes)
        nodes_ast = [ nodes_ast, external_nodes];
    else
        nodes_ast{end + 1} = external_nodes;
    end
    if ~isempty(main_node)
        nodes_ast{end + 1} = main_node;
    end
end
end

%%
function display_help_message()
msg = ' -----------------------------------------------------  \n';
msg = [msg '  CoCoSim: Automated Analysis Framework for Simulink/Stateflow\n'];
msg = [msg '   \n Usage:\n'];
msg = [msg '    >> ToLustre(MODEL_PATH, {MAT_CONSTANTS_FILES}, backend, options)\n'];
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

