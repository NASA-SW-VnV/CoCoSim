function [unsupportedOptions, ...
        status,...
        model_full_path, ...
        ir_struct, ...
        output_dir, ...
        abstractedBlocks] =...
        ToLustreUnsupportedBlocks(model_path, const_files, lus_backend, coco_backend, varargin)
    
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
    
    import nasa_toLustre.*
    import nasa_toLustre.utils.*
    import nasa_toLustre.IR_pp.internalRep_pp
    %% inputs treatment
    
    narginchk(1, inf);
    
    
    if ~exist('const_files', 'var') || isempty(const_files)
        const_files = {};
    end
    mode_display = 1;
    try
        skip_unsupportedblocks = evalin('base', 'skip_unsupportedblocks');
    catch
        skip_unsupportedblocks = 0;
    end
    for i=1:numel(varargin)
        if strcmp(varargin{i}, ToLustreOptions.NODISPLAY)
            mode_display = 0;
        elseif strcmp(varargin{i}, ToLustreOptions.SKIP_COMPATIBILITY)
            skip_unsupportedblocks = 1;
        end
    end
    if ~exist('lus_backend', 'var') || isempty(lus_backend)
        lus_backend = LusBackendType.LUSTREC;
    end
    if ~exist('coco_backend', 'var') || isempty(coco_backend)
        coco_backend = CoCoBackendType.COMPATIBILITY;
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
    varargin{end+1} = ToLustreOptions.SKIP_DEFECTED_PP;
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
    
    % add enumeration from Stateflow and from IR
    add_IR_Enum(ir_struct);
    
    %% Unsupported blocks detection
    if skip_unsupportedblocks
        display_msg('skip_unsupportedblocks flag is given. Skipping unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');
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
    [unsupportedOptionsMap, abstractedBlocks] = ...
        recursiveGeneration(main_block, main_block, main_sampleTime, lus_backend, coco_backend, unsupportedOptionsMap);
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
function [unsupportedOptionsMap, abstractedBlocks]= ...
        recursiveGeneration(parent, blk, main_sampleTime, lus_backend, coco_backend, unsupportedOptionsMap)
    [unsupportedOptionsMap, abstractedBlocks] = blockUnsupportedOptions(parent, blk, main_sampleTime, lus_backend, coco_backend, unsupportedOptionsMap);
    if isfield(blk, 'Content')
        field_names = fieldnames(blk.Content);
        field_names = ...
            field_names(...
            cellfun(@(x) isfield(blk.Content.(x),'BlockType'), field_names));
        for i=1:numel(field_names)
            [unsupportedOptionsMap, abstractedBlocks_i] = recursiveGeneration(blk, blk.Content.(field_names{i}), main_sampleTime, lus_backend, coco_backend, unsupportedOptionsMap);
            abstractedBlocks = [abstractedBlocks , abstractedBlocks_i];
        end
    end
end

function  [unsupportedOptionsMap, abstractedBlocks]  = blockUnsupportedOptions( parent, blk,  main_sampleTime, lus_backend, coco_backend, unsupportedOptionsMap)
    %blockUnsupportedOptions get unsupported options of a bock.
    %INPUTS:
    %   blk: The internal representation of the subsystem.
    %   main_clock   : The model sample time.
    [b, status, type, masktype, sfblockType, isIgnored] = nasa_toLustre.utils.getWriteType(blk);
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
            htmlMsg = HtmlItem(msg, {}, 'black', [], [], false);
            if isKey(unsupportedOptionsMap, blkType)
                unsupportedOptionsMap(blkType) = [unsupportedOptionsMap(blkType), {htmlMsg}];
            else
                unsupportedOptionsMap(blkType) = {htmlMsg};
            end
        end
        return;
    end
    unsupportedOptions_i = b.getUnsupportedOptions(parent, blk, lus_backend,...
        coco_backend, main_sampleTime);
    if ~isempty(unsupportedOptions_i)
        htmlMsg = cellfun(@(x) HtmlItem(x, {}, 'black', [], [], false),unsupportedOptions_i, 'UniformOutput', false);
        if isKey(unsupportedOptionsMap, blkType)
            unsupportedOptionsMap(blkType) = [unsupportedOptionsMap(blkType), htmlMsg];
        else
            unsupportedOptionsMap(blkType) = htmlMsg;
        end
    end
    is_abstracted = b.isAbstracted(lus_backend, parent, blk, main_sampleTime);
    if is_abstracted
        msg = sprintf('Block "%s" with Type "%s".', ...
            HtmlItem.addOpenCmd(blk.Origin_path), blkType);
        abstractedBlocks = {msg};
    end
end


%% add enumeration from IR
function add_IR_Enum(ir)
    global TOLUSTRE_ENUMS_MAP TOLUSTRE_ENUMS_CONV_NODES;
    if isfield(ir, 'meta') && isfield(ir.meta, 'Declarations') ...
            && isfield(ir.meta.Declarations, 'Enumerations')
        enums = ir.meta.Declarations.Enumerations;
        for i=1:numel(enums)
            % put the type name in LOWER case: Lustrec limitation
            name = lower(enums{i}.Name);
            if isKey(TOLUSTRE_ENUMS_MAP, name)
                continue;
            end
            members = enums{i}.Members;
            % add defaultValue in first.
            Names = cellfun(@(x) x.Name, members, 'UniformOutput', false);
            Names = Names(~strcmp(Names, enums{i}.DefaultValue));
            % put member in UPPER case: Lustrec limitation
            names_in_order = [{enums{i}.DefaultValue}; Names];
            names_ast = cellfun(@(x) EnumValueExpr(x), names_in_order, ...
                'UniformOutput', false);
            TOLUSTRE_ENUMS_MAP(name) = names_ast;
            TOLUSTRE_ENUMS_CONV_NODES{end+1} = get_Enum2Int_conv_node(name, members);
            TOLUSTRE_ENUMS_CONV_NODES{end+1} = get_Int2Enum_conv_node(name, members);
        end
    end
end
function node = get_Enum2Int_conv_node(name, members)
    conds = cell(numel(members), 1);
    thens = cell(numel(members) + 1, 1);
    for i=1:numel(members)
        conds{i} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), ...
            EnumValueExpr(members{i}.Name));
        thens{i} = IntExpr(members{i}.Value);
    end
    thens{end} = IntExpr(0);
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(conds, thens));
    node = LustreNode();
    node.setName(strcat(name, '_to_int'));
    node.setInputs(LustreVar('x', name));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
function node = get_Int2Enum_conv_node(name, members)
    conds = cell(numel(members)-1, 1);
    thens = cell(numel(members), 1);
    for i=1:numel(members)-1
        conds{i} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), ...
            IntExpr(members{i}.Value));
        thens{i} = EnumValueExpr(members{i}.Name);
    end
    thens{end} = EnumValueExpr(members{end}.Name);
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(conds, thens));
    node = LustreNode();
    node.setName(strcat('int_to_', name));
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', name));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end