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
    
    
    if ~exist('const_files', 'var') || isempty(const_files)
        const_files = {};
    end
    mode_display = 1;
    skip_unsupportedblocks = 0;
    for i=1:numel(varargin)
        if strcmp(varargin{i}, 'nodisplay')
            mode_display = 0;
        elseif strcmp(varargin{i}, 'skip_unsupportedblocks')
            skip_unsupportedblocks = 1;
        end
    end
    if ~exist('backend', 'var') || isempty(backend)
        backend = BackendType.LUSTREC;
    end
    
    
    %% initialize result
    unsupportedOptions = {};
    status = 0;
    ir_struct = {};
    output_dir = '';
    abstractedBlocks = {};
    %% Get start time
    t_start = tic;
    
    %% Get Simulink model full path
    if exist(model_path, 'file') == 4
        model_full_path = which(model_path);
    else
        model_full_path = model_path;
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
    global ir_handle_struct_map;
    [ir_struct, ir_handle_struct_map] = internalRep_pp(ir_struct, 1, output_dir);
    
    
    
    %% Unsupported blocks detection
    if skip_unsupportedblocks
        display_msg('Skipping unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');
        return;
    end
    display_msg('Unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');
    
    
    main_block = ir_struct.(IRUtils.name_format(file_name));
    main_sampleTime = main_block.CompiledSampleTime;
    if numel(main_sampleTime) >= 2 && main_sampleTime(2) ~= 0
        msg = sprintf('Your model is running with a CompiledSampleTime [%d, %d], offset time not null is not supported in the root level.',...
            main_sampleTime(1), main_sampleTime(2));
        unsupportedOptions{1} = ...
            HtmlItem('Model', ...
            HtmlItem(msg, {}, 'black', [], [], false),...
            'blue');
    end
    unsupportedOptionsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    [unsupportedOptionsMap, abstractedBlocks] = recursiveGeneration(main_block, main_block, main_sampleTime, backend, unsupportedOptionsMap);
    keys = unsupportedOptionsMap.keys();
    for i=1:numel(keys)
        k = keys{i};
        unsupportedOptions{end+1} = HtmlItem(k, unsupportedOptionsMap(k), 'blue');
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
            MenuUtils.createHtmlListUsingHTMLITEM('Unsupported options/blocks', unsupportedOptions, html_path, file_name);
            msg = sprintf('HTML report is in : %s', html_path);
            display_msg(msg, MsgType.ERROR, 'ToLustreUnsupportedBlocks', '');
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'unsupportedBlocksMenu', '');
            unsupportedOptions_text = cellfun(@(x) x.print_noHTML(), unsupportedOptions, 'UniformOutput', false);
            msg = sprintf('Your model is incompatible with CoCoSim for the following reasons:\n%s', ...
                MatlabUtils.strjoin(unsupportedOptions_text, '\n\n'));
            msgbox(msg, 'Error','error');
        end
    else
        unsupportedOptions_text = cellfun(@(x) x.print_noHTML(), unsupportedOptions, 'UniformOutput', false);
        display_msg(MatlabUtils.strjoin(unsupportedOptions_text, '\n'), ...
            MsgType.ERROR, 'ToLustreUnsupportedBlocks', '');
    end
    
    t_finish = toc(t_start);
    msg = sprintf('ToLustreUnsupportedBlocks finished in %f seconds', t_finish);
    display_msg(msg, MsgType.RESULT, 'ToLustreUnsupportedBlocks', '');
    cd(PWD)
end

%%
function [unsupportedOptionsMap, abstractedBlocks]= recursiveGeneration(parent, blk, main_sampleTime, backend, unsupportedOptionsMap)
    [unsupportedOptionsMap, abstractedBlocks] = blockUnsupportedOptions(parent, blk, main_sampleTime, backend, unsupportedOptionsMap);
    if isfield(blk, 'Content')
        field_names = fieldnames(blk.Content);
        field_names = ...
            field_names(...
            cellfun(@(x) isfield(blk.Content.(x),'BlockType'), field_names));
        for i=1:numel(field_names)
            [unsupportedOptionsMap, abstractedBlocks_i] = recursiveGeneration(blk, blk.Content.(field_names{i}), main_sampleTime, backend, unsupportedOptionsMap);
            abstractedBlocks = [abstractedBlocks , abstractedBlocks_i];
        end
    end
end

function  [unsupportedOptionsMap, abstractedBlocks]  = blockUnsupportedOptions( parent, blk,  main_sampleTime, backend, unsupportedOptionsMap)
    %blockUnsupportedOptions get unsupported options of a bock.
    %INPUTS:
    %   blk: The internal representation of the subsystem.
    %   main_clock   : The model sample time.
    [b, status, type, masktype, sfblockType, isIgnored] = getWriteType(blk);
    if ~isempty(sfblockType)
        blkType = sfblockType;
    elseif ~isempty(masktype)
        blkType = masktype;
    else
        blkType = type;
    end
    abstractedBlocks = {};
    if status
        if ~isIgnored
            msg = sprintf('Block "%s" with Type "%s" is not supported', ...
                HtmlItem.addOpenCmd(blk.Origin_path), blkType);
            htmlMsg = HtmlItem(msg, {}, 'black');
            if isKey(unsupportedOptionsMap, blkType)
                unsupportedOptionsMap(blkType) = [unsupportedOptionsMap(blkType), htmlMsg];
            else
                unsupportedOptionsMap(blkType) = htmlMsg;
            end
        end
        return;
    end
    unsupportedOptions_i = b.getUnsupportedOptions(parent, blk,  main_sampleTime, backend);
    if ~isempty(unsupportedOptions_i)
        htmlMsg = cellfun(@(x) HtmlItem(x, {}, 'black', [], [], false),unsupportedOptions_i, 'UniformOutput', false);
        if isKey(unsupportedOptionsMap, blkType)
            unsupportedOptionsMap(blkType) = [unsupportedOptionsMap(blkType), htmlMsg];
        else
            unsupportedOptionsMap(blkType) = htmlMsg;
        end
    end
    is_abstracted = b.isAbstracted(backend, parent, blk, main_sampleTime);
    if is_abstracted
        msg = sprintf('Block "%s" with Type "%s".', ...
            HtmlItem.addOpenCmd(blk.Origin_path), blkType);
        abstractedBlocks = {msg};
    end
end

