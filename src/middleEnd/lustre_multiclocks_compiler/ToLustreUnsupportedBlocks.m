function [unsupportedOptions]= ToLustreUnsupportedBlocks(model_path, const_files, varargin)
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

narginchk(1, 2);

if ~exist('const_files', 'var') || isempty(const_files)
    const_files = {};
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
%% Save current path
PWD = pwd;

%% Run constants
SLXUtils.run_constants_files(const_files);


%% Pre-process model
display_msg('Pre-processing', MsgType.INFO, 'ToLustreUnsupportedBlocks', '');
[new_file_name, status] = cocosim_pp(model_full_path ,'nodisplay',  varargin{:});
if status
    return;
end
%% Update model path with the pre-processed model
if ~strcmp(new_file_name, '')
    model_full_path = new_file_name;
    [model_dir, file_name, ~] = fileparts(model_full_path);
else
    display_msg('Pre-processing has failed', MsgType.ERROR, 'ToLustreUnsupportedBlocks', '');
    return;
end




%% Internal representation building %%%%%%
display_msg('Building internal format', MsgType.INFO, 'ToLustreUnsupportedBlocks', '');
[ir_struct, ~, ~, ~] = cocosim_IR(model_full_path);
% Pre-process IR
[ir_struct] = internalRep_pp(ir_struct);


%% Unsupported blocks detection
display_msg('Unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');


main_block = ir_struct.(IRUtils.name_format(file_name));
main_sampleTime = main_block.CompiledSampleTime;

unsupportedOptions = recursiveGeneration(main_block, main_sampleTime);

%% display report files
if isempty(unsupportedOptions)
    if exist('success.png', 'file')
        [icondata,iconcmap] = imread('success.png');
        msgbox('Your model is compatible with CoCoSim!','Success','custom',icondata,iconcmap);
    else
        msgbox('Your model is compatible with CoCoSim!');
    end
else
    try
        output_dir = fullfile(model_dir, 'cocosim_output', file_name);
        html_path = fullfile(output_dir, strcat(file_name, '_unsupportedOptions.html'));
        if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
        MenuUtils.createHtmlList('Unsupported options/blocks', unsupportedOptions, html_path);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'unsupportedBlocksMenu', '');
        msg = sprintf('Your model is incompatible with CoCoSim for the following reasons:\n%s', ...
            MatlabUtils.strjoin(unsupportedOptions, '\n\n'));
        msgbox(msg, 'Error','error');
    end
end

t_finish = toc(t_start);
msg = sprintf('ToLustreUnsupportedBlocks finished in %f seconds', t_finish);
display_msg(MatlabUtils.strjoin(unsupportedOptions, '\n'), MsgType.DEBUG, 'ToLustreUnsupportedBlocks', '');
display_msg(msg, MsgType.RESULT, 'ToLustreUnsupportedBlocks', '');
cd(PWD)
end

%%
function unsupportedOptions= recursiveGeneration(blk, main_sampleTime)
unsupportedOptions = {};
unsupportedOptions_i = blockUnsupportedOptions(blk, main_sampleTime);
unsupportedOptions = [unsupportedOptions, unsupportedOptions_i];
if isfield(blk, 'Content')
    field_names = fieldnames(blk.Content);
    for i=1:numel(field_names)
        unsupportedOptions_i = recursiveGeneration(blk.Content.(field_names{i}), main_sampleTime);
        unsupportedOptions = [unsupportedOptions, unsupportedOptions_i];
    end
end
end

function  unsupportedOptions_i  = blockUnsupportedOptions( blk,  main_sampleTime)
%blockUnsupportedOptions get unsupported options of a bock.
%INPUTS:
%   blk: The internal representation of the subsystem.
%   main_clock   : The model sample time.
[b, status, type] = getWriteType(blk);
unsupportedOptions_i = {};
if status
    if ~Block_To_Lustre.ignored(type)
        msg = sprintf('BlockType "%s" is not supported in "%s"', type, blk.Origin_path);
        unsupportedOptions_i = {msg};
    end
    return;
end
unsupportedOptions_i = b.getUnsupportedOptions(blk,  main_sampleTime);

end

