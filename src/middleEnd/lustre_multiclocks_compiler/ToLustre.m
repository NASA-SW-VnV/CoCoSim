function [nom_lustre_file, xml_trace, status, unsupportedOptions, abstractedBlocks, pp_model_full_path]= ...
    ToLustre(model_path, const_files, backend, varargin)
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

%% global variables
global TOLUSTRE_ENUMS_MAP;
TOLUSTRE_ENUMS_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
%% Get start time
t_start = tic;

%% inputs treatment
if nargin < 1
    display_help_message();
    return;
end
if ~exist('const_files', 'var') || isempty(const_files)
    const_files = {};
end
if ~exist('backend', 'var') || isempty(backend)
    backend = BackendType.LUSTREC; 
end
forceGeneration = 0;
for i=1:numel(varargin)
    if strcmp(varargin{i}, 'forceCodeGen')
        forceGeneration = 1;
        break;
    end
end
if ~forceGeneration
    try
        forceGeneration = evalin('base', 'cocosim_force');
    catch
        forceGeneration = 0;
    end
end
    
%% initialize outputs
nom_lustre_file = '';
xml_trace = [];
status = 0;
unsupportedOptions = {};
abstractedBlocks = {};
pp_model_full_path = '';
%% Get Simulink model full path
if exist(model_path, 'file') == 4
    model_path = which(model_path);
end
if ~exist(model_path, 'file')
    error('Model "%s" Does not exist', model_path);
end
%% skip translation if no modification has been made to the model.
persistent ToLustre_datenum_map;
if isempty(ToLustre_datenum_map)
    ToLustre_datenum_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
end
if ~forceGeneration && isKey(ToLustre_datenum_map, model_path)
    nom_lustre_file = ToLustre_datenum_map(model_path);
    if BUtils.isLastModified(model_path, nom_lustre_file)
        mat_file = regexprep(nom_lustre_file, '.lus$', '.mat');
        if exist(mat_file, 'file')
            M = load(mat_file);
            if exist(M.pp_model_full_path, 'file') ...
                    && BUtils.isLastModified(M.pp_model_full_path, nom_lustre_file)
                xml_trace = M.xml_trace;
                status = M.status;
                unsupportedOptions = M.unsupportedOptions;
                abstractedBlocks = M.abstractedBlocks;
                pp_model_full_path = M.pp_model_full_path;
                display_msg('Skipping Lustre generation step. Using previously generated code, no modifications have been made to the model.',...
                    MsgType.RESULT, 'ToLustre', '');
                return;
            end
        end
    end
end


try
    [unsupportedOptions, status, pp_model_full_path, ir_struct, output_dir, abstractedBlocks]= ...
        ToLustreUnsupportedBlocks(model_path, const_files, backend, varargin{:});
    
    if status || ~isempty(unsupportedOptions)
        return;
    end
catch me
    display_msg(me.getReport(), MsgType.DEBUG, 'ToLustre', '');
    status = 1;
    return;
end
[~, file_name, ~] = fileparts(pp_model_full_path);
%% Definition of the generated output files names
nom_lustre_file = fullfile(output_dir, strcat(file_name,'.', backend, '.lus'));
mat_file = fullfile(output_dir, strcat(file_name,'.', backend, '.mat'));

%% Create Meta informations
create_file_meta_info(nom_lustre_file);

%% Create traceability informations in XML format
display_msg('Start tracebility', MsgType.INFO, 'lustre_multiclocks_compiler', '');
xml_trace_file_name = fullfile(output_dir, strcat(file_name, '.toLustre.trace.xml'));
json_trace_file_name = fullfile(output_dir, strcat(file_name, '_mapping.json'));
xml_trace = SLX2Lus_Trace(pp_model_full_path,...
    xml_trace_file_name, json_trace_file_name);



%% Lustre generation
display_msg('Lustre generation', Constants.INFO, 'lustre_multiclocks_compiler', '');

global model_struct
model_struct = ir_struct.(IRUtils.name_format(file_name));
main_sampleTime = model_struct.CompiledSampleTime;
is_main_node = 1;
[nodes_ast, contracts_ast, external_libraries, status] = recursiveGeneration(...
    model_struct, model_struct, main_sampleTime, is_main_node, backend, xml_trace);
if status
    return;
end
[external_lib_code, open_list, abstractedNodes] = getExternalLibrariesNodes(external_libraries, backend);
abstractedBlocks = [abstractedBlocks, abstractedNodes];
if ~isempty(abstractedBlocks)
    display_msg('The following Blocks/Nodes are abstracted:', ...
        MsgType.WARNING, 'ToLustreUnsupportedBlocks', '');
    display_msg(MatlabUtils.strjoin(abstractedBlocks, '\n'), ...
        MsgType.WARNING, 'ToLustreUnsupportedBlocks', '');
end
%TODO: change it to AST
nodes_ast = [external_lib_code, nodes_ast];
%% create LustreProgram
keys = TOLUSTRE_ENUMS_MAP.keys();
enumsAst = cell(numel(keys), 1);
for i=1:numel(keys)
    enumsAst{i} = EnumTypeExpr(keys{i}, TOLUSTRE_ENUMS_MAP(keys{i}));
end            
program =  LustreProgram(open_list, enumsAst, nodes_ast, contracts_ast);

% copy Kind2 libraries
if BackendType.isKIND2(backend) 
    if ismember('lustrec_math', open_list)
        lib_path = fullfile(fileparts(mfilename('fullpath')),...
            'lib', 'lustrec_math.lus');
        copyfile(lib_path, output_dir);
    end
    if ismember('simulink_math_fcn', open_list)
        lib_path = fullfile(fileparts(mfilename('fullpath')),...
            'lib', 'simulink_math_fcn.lus');
        copyfile(lib_path, output_dir);
    end
end
%% writing code
fid = fopen(nom_lustre_file, 'a');
if fid==-1
    msg = sprintf('Opening file "%s" is not possible', nom_lustre_file);
    display_msg(msg, MsgType.ERROR, 'lustre_multiclocks_compiler', '');
end
try
    Lustrecode = program.print(backend);
    fprintf(fid, '%s', Lustrecode);
    fclose(fid);
catch me
    display_msg('Printing Lustre AST to file failed',...
        MsgType.ERROR, 'write_body', '');
    display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
    status = 1;
    return;
end


%% writing traceability
xml_trace.write();

%% save results in mat file.
save(mat_file, 'xml_trace', 'status', 'unsupportedOptions', 'abstractedBlocks', 'pp_model_full_path');
ToLustre_datenum_map(model_path) = nom_lustre_file;

%% display report files
t_finish = toc(t_start);
display_msg(Lustrecode, MsgType.DEBUG, 'lustre_multiclocks_compiler', '');
msg = sprintf('Lustre File generated:%s', nom_lustre_file);
display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');
msg = sprintf('Lustre generation finished in %f seconds', t_finish);
display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');


end

%%
function [nodes_ast, contracts_ast, external_libraries, error_status] = recursiveGeneration(parent, blk, main_sampleTime, is_main_node, backend, xml_trace)
nodes_ast = {};
contracts_ast = {};
external_libraries = {};
error_status = false;
if isfield(blk, 'Content') && ~isempty(blk.Content) ...
        && ~(isstruct(blk.Content) && isempty(fieldnames(blk.Content)))
    field_names = fieldnames(blk.Content);
    for i=1:numel(field_names)
        
        [nodes_code_i, contracts_ast_i, external_libraries_i, error_status_i] = recursiveGeneration(blk, blk.Content.(field_names{i}), main_sampleTime, 0, backend, xml_trace);
        if ~isempty(nodes_code_i)
            nodes_ast = [ nodes_ast, nodes_code_i];
        end
        if ~isempty(contracts_ast_i)
            contracts_ast = [ contracts_ast, contracts_ast_i];
        end
        external_libraries = [external_libraries, external_libraries_i];
        error_status = error_status_i || error_status;
    end
    [b, status] = getWriteType(blk);
    if status || ~b.isContentNeedToBeTranslated()
        return;
    end
    try
        [main_node, is_contract, external_nodes, external_libraries_i] = SS_To_LustreNode.subsystem2node(parent, blk, main_sampleTime, is_main_node, backend, xml_trace);
    catch me
        display_msg(sprintf('Translation to Lustre of block %s has failed.', blk.Origin_path),...
            MsgType.ERROR, 'write_body', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
        error_status = true;
        return;
    end
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
    
    try
        % OLD compiler
        %[main_node, ~, external_nodes, external_libraries_i] = ...
        %    SS_To_LustreNode.subsystem2node(parent, blk, main_sampleTime, is_main_node, backend, xml_trace);
        
        % new compiler
        [main_node, external_nodes, external_libraries_i ] = ...
            SF_To_LustreNode.chart2node(parent,  blk,  main_sampleTime, backend, xml_trace);
    catch me
        display_msg(sprintf('Translation to Lustre of block %s has failed.', blk.Origin_path),...
            MsgType.ERROR, 'write_body', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
        error_status = true;
        return;
    end
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

