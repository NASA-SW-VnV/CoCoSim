function [unsupportedOptions, ...
    status,...
    model_full_path, ...
    ir_struct, ...
    output_dir, ...
    abstractedBlocks] =...
    ToLustreUnsupportedBlocks(model_path, const_files, backend, varargin)
%ToLustreUnsupportedBlocks detects unsupported options/blocks in Simulink model.
%INPUTS:
%   MODEL_PATH: The full path of the Simulink model.
%   CONST_FILES: The list of constant files to be run in order to be able
%   to simulate the simulink model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% inputs treatment

narginchk(1, inf);
status = 0;
abstractedBlocks = {};
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


%% initialize result
unsupportedOptions = {};

%% Get start time
t_start = tic;

%% Get Simulink model full path
if (exist(model_path, 'file') == 2 || exist(model_path, 'file') == 4)
    model_full_path = model_path;
else
    model_full_path = which(model_path);
end
if ~exist(model_full_path, 'file')
    status = 1;
    error('Model "%s" Does not exist', model_path);
end
%% Save current path
PWD = pwd;

%% Run constants
SLXUtils.run_constants_files(const_files);


%% Pre-process model
display_msg('Pre-processing', MsgType.INFO, 'ToLustreUnsupportedBlocks', '');
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
    status = 1;
    display_msg('Pre-processing has failed', MsgType.ERROR, 'ToLustreUnsupportedBlocks', '');
    return;
end



output_dir = fullfile(model_dir, 'cocosim_output', file_name);
if ~exist(output_dir, 'dir'); mkdir(output_dir); end
%% Internal representation building %%%%%%
display_msg('Building internal format', MsgType.INFO, 'ToLustreUnsupportedBlocks', '');
[ir_struct, ~, ~, ~] = cocosim_IR(model_full_path,  0, output_dir);
% Pre-process IR
[ir_struct] = internalRep_pp(ir_struct, 1, output_dir);


%% Unsupported blocks detection
display_msg('Unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');


main_block = ir_struct.(IRUtils.name_format(file_name));
main_sampleTime = main_block.CompiledSampleTime;
if numel(main_sampleTime) >= 2 && main_sampleTime(2) ~= 0
    unsupportedOptions{end+1} = sprintf('Your model is running with a CompiledSampleTime [%d, %d], offset time not null is not supported in the root level.',...
        main_sampleTime(1), main_sampleTime(2));
else
    [unsupportedOptions, abstractedBlocks] = recursiveGeneration(main_block, main_block, main_sampleTime, backend);
end
%% display report files
if isempty(unsupportedOptions)
    if mode_display == 1
        if exist('success.png', 'file')
            [icondata,iconcmap] = imread('success.png');
            msgbox('Your model is compatible with CoCoSim!','Success','custom',icondata,iconcmap);
        else
            msgbox('Your model is compatible with CoCoSim!');
        end
    else
        display_msg('Your model is compatible with CoCoSim!', ...
            MsgType.RESULT, 'ToLustreUnsupportedBlocks', '');
    end
elseif mode_display == 1
    try
        output_dir = fullfile(model_dir, 'cocosim_output', file_name);
        html_path = fullfile(output_dir, strcat(file_name, '_unsupportedOptions.html'));
        if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
        MenuUtils.createHtmlList('Unsupported options/blocks', unsupportedOptions, html_path);
        msg = sprintf('HTML report is in : %s', html_path);
        display_msg(msg, MsgType.ERROR, 'ToLustreUnsupportedBlocks', '');
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'unsupportedBlocksMenu', '');
        msg = sprintf('Your model is incompatible with CoCoSim for the following reasons:\n%s', ...
            MatlabUtils.strjoin(unsupportedOptions, '\n\n'));
        msgbox(msg, 'Error','error');
    end
else
    display_msg(MatlabUtils.strjoin(unsupportedOptions, '\n'), ...
        MsgType.ERROR, 'ToLustreUnsupportedBlocks', '');
end

t_finish = toc(t_start);
msg = sprintf('ToLustreUnsupportedBlocks finished in %f seconds', t_finish);
display_msg(msg, MsgType.RESULT, 'ToLustreUnsupportedBlocks', '');
cd(PWD)
end

%%
function [unsupportedOptions, abstractedBlocks]= recursiveGeneration(parent, blk, main_sampleTime, backend)
unsupportedOptions = {};
[unsupportedOptions_i, abstractedBlocks] = blockUnsupportedOptions(parent, blk, main_sampleTime, backend);
unsupportedOptions = [unsupportedOptions, unsupportedOptions_i];
if isfield(blk, 'Content')
    field_names = fieldnames(blk.Content);
    field_names = ...
        field_names(...
        cellfun(@(x) isfield(blk.Content.(x),'BlockType'), field_names));
    for i=1:numel(field_names)
        [unsupportedOptions_i, abstractedBlocks_i] = recursiveGeneration(blk, blk.Content.(field_names{i}), main_sampleTime, backend);
        unsupportedOptions = [unsupportedOptions, unsupportedOptions_i];
        abstractedBlocks = [abstractedBlocks , abstractedBlocks_i];
    end
end
end

function  [unsupportedOptions_i, abstractedBlocks]  = blockUnsupportedOptions( parent, blk,  main_sampleTime, backend)
%blockUnsupportedOptions get unsupported options of a bock.
%INPUTS:
%   blk: The internal representation of the subsystem.
%   main_clock   : The model sample time.
[b, status, type, masktype, isIgnored] = getWriteType(blk);
unsupportedOptions_i = {};
abstractedBlocks = {};
if status
    if ~isIgnored
        if isempty(masktype)
            msg = sprintf('Block "%s" with BlockType "%s" is not supported', blk.Origin_path, type);
        else
            msg = sprintf('Block "%s" with BlockType "%s" and MaskType "%s" is not supported', blk.Origin_path, type, masktype);
        end
        unsupportedOptions_i = {msg};
    end
    return;
end
unsupportedOptions_i = b.getUnsupportedOptions(parent, blk,  main_sampleTime);
is_abstracted = b.isAbstracted(backend, parent, blk, main_sampleTime);
if is_abstracted
    if isempty(masktype)
        msg = sprintf('Block "%s" with BlockType "%s".', blk.Origin_path, type);
    else
        msg = sprintf('Block "%s" with BlockType "%s" and MaskType "%s".', blk.Origin_path, type, masktype);
    end
    abstractedBlocks = {msg};
end
end

