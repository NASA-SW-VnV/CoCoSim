%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [unsupportedOptions, ...
        failed,...
        model_full_path, ...
        ir_struct, ...
        output_dir, ...
        abstractedBlocks, ...
        ir_json_path] =...
        ToLustreUnsupportedBlocks(model_path, const_files, lus_backend, coco_backend, varargin)
    
    %ToLustreUnsupportedBlocks detects unsupported options/blocks in Simulink model.
    %INPUTS:
    %   MODEL_PATH: The full path of the Simulink model.
    %   CONST_FILES: The list of constant files to be run in order to be able
    %   to simulate the simulink model.

    global TOLUSTRE_ENUMS_MAP CoCoSimPreferences
            
    if isempty(CoCoSimPreferences)
        CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    end
    %% inputs treatment
    
    narginchk(1, inf);
    if isempty(TOLUSTRE_ENUMS_MAP)
        TOLUSTRE_ENUMS_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    if ~exist('const_files', 'var') || isempty(const_files)
        const_files = {};
    end
    mode_display = 1;
    try
        skip_unsupportedblocks = evalin('base', 'skip_unsupportedblocks');
    catch
        skip_unsupportedblocks = CoCoSimPreferences.skip_unsupportedblocks;
    end
    for i=1:numel(varargin)
        if strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.NODISPLAY)
            mode_display = 0;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.SKIP_COMPATIBILITY)
            skip_unsupportedblocks = 1;
        end
    end
    if ~exist('lus_backend', 'var') || isempty(lus_backend)
        lus_backend = coco_nasa_utils.LusBackendType.LUSTREC;
    end
    if ~exist('coco_backend', 'var') || isempty(coco_backend)
        coco_backend = coco_nasa_utils.CoCoBackendType.COMPATIBILITY;
    end
    
    %% initialize result
    unsupportedOptions = {};
    failed = 0;
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
        failed = 1;
        error('Model "%s" Does not exist', model_path);
    end
    %% Save current path
    PWD = pwd;
    
    %% Run constants
    coco_nasa_utils.SLXUtils.run_constants_files(const_files);
    
    
    %% Pre-process model
    display_msg('Pre-processing', MsgType.INFO, 'ToLustreUnsupportedBlocks', '');
    varargin{end+1} = nasa_toLustre.utils.ToLustreOptions.SKIP_DEFECTED_PP;
    [new_file_name, failed] = cocosim_pp(model_full_path , varargin{:});
    if failed
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
        failed = 1;
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
    [ir_struct, ir_handle_struct_map, ir_json_path] = nasa_toLustre.IR_pp.internalRep_pp(ir_struct, 1, output_dir);
    
    % add enumeration from Stateflow and from IR
    add_IR_Enum(ir_struct, lus_backend);
    
    %% Unsupported blocks detection
    if skip_unsupportedblocks
        display_msg('skip_unsupportedblocks flag is given. Skipping unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');
        return;
    end
    display_msg('Unsupported blocks detection', Constants.INFO, 'ToLustreUnsupportedBlocks', '');
    
    
    
    main_block = ir_struct.(IRUtils.name_format(file_name));
    main_sampleTime = main_block.CompiledSampleTime;
    
    % detecte if the model has unsupported options
    htmlItemMsg = nasa_toLustre.utils.SLX2LusUtils.modelCompatibilityCheck(file_name, main_sampleTime);
    if ~isempty(htmlItemMsg)
        unsupportedOptions{1} = htmlItemMsg;
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
        msg = sprintf(['The model does not contain unsupported blocks.\n' ...
            'Some blocks may be partially supported.\n'...
            'When running verification or code generation, other errors may appear if some blocks are partially supported.']);
        if mode_display == 1
            
            if exist('success.png', 'file')
                [icondata,iconcmap] = imread('success.png');
                msgbox(msg,'Success','custom',icondata,iconcmap);
            else
                msgbox(msg);
            end
        end
        % display it too in command window.
        display_msg(msg, MsgType.RESULT, 'ToLustreUnsupportedBlocks', '');
        
    elseif mode_display == 1
        try
            output_dir = fullfile(model_dir, 'cocosim_output', file_name);
            f_base = strcat(file_name, '_unsupportedOptions.html');
            html_path = fullfile(output_dir, f_base);
            if ~exist(output_dir, 'dir'); coco_nasa_utils.MatlabUtils.mkdir(output_dir); end
            coco_nasa_utils.MenuUtils.createHtmlListUsingHTMLITEM('Unsupported options/blocks', unsupportedOptions, html_path, file_name);
            msg = sprintf('HTML report of Unsupported options/blocks is in : %s', HtmlItem.addOpenFileCmd(html_path, f_base));
            display_msg(msg, MsgType.RESULT, 'ToLustreUnsupportedBlocks', '');
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'unsupportedBlocksMenu', '');
            unsupportedOptions_text = cellfun(@(x) x.print_noHTML(), unsupportedOptions, 'UniformOutput', false);
            msg = sprintf('Your model is incompatible with CoCoSim for the following reasons:\n%s', ...
                coco_nasa_utils.MatlabUtils.strjoin(unsupportedOptions_text, '\n\n'));
            msgbox(msg, 'Error','error');
        end
    else
        unsupportedOptions_text = cellfun(@(x) x.print_noHTML(), unsupportedOptions, 'UniformOutput', false);
        display_msg(coco_nasa_utils.MatlabUtils.strjoin(unsupportedOptions_text, '\n'), ...
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
    [b, status, type, masktype, sfblockType, isIgnored] = nasa_toLustre.utils.getWriteType(blk, lus_backend);
    if ~isempty(sfblockType) && ~strcmp(sfblockType, 'NONE')
        blkType = sfblockType;
    elseif ~isempty(masktype)
        blkType = masktype;
    else
        blkType = type;
    end
    abstractedBlocks = {};
    if status || isa(b, 'nasa_toLustre.blocks.AbstractBlock_To_Lustre')
        if ~isIgnored            
            msg = sprintf('Block "%s" with Type "%s" is not supported', ...
                HtmlItem.addOpenCmd(blk.Origin_path), blkType);
            htmlMsg = HtmlItem(msg, {}, 'black');
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
        htmlMsg = cellfun(@(x) HtmlItem(x, {}, 'black'),unsupportedOptions_i, 'UniformOutput', false);
        if isKey(unsupportedOptionsMap, blkType)
            unsupportedOptionsMap(blkType) = [unsupportedOptionsMap(blkType), htmlMsg];
        else
            unsupportedOptionsMap(blkType) = htmlMsg;
        end
    end
    is_abstracted = b.isAbstracted(parent, blk, lus_backend, coco_backend, main_sampleTime);
    if is_abstracted
        msg = sprintf('Block "%s" with Type "%s".', ...
            HtmlItem.addOpenCmd(blk.Origin_path), blkType);
        abstractedBlocks = {msg};
    end
end


%% add enumeration from IR
function add_IR_Enum(ir, lus_backend)
    global TOLUSTRE_ENUMS_MAP TOLUSTRE_ENUMS_CONV_NODES;
    if isfield(ir, 'meta') && isfield(ir.meta, 'Declarations') ...
            && isfield(ir.meta.Declarations, 'Enumerations')
        enums = ir.meta.Declarations.Enumerations;
        for i=1:numel(enums)
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
                name = enums{i}.Name;
            else
                % put the type name in LOWER case: Lustrec limitation
                name = lower(enums{i}.Name);
            end
            if isKey(TOLUSTRE_ENUMS_MAP, name)
                continue;
            end
            members = enums{i}.Members;
            % add defaultValue in first.
            Names = cellfun(@(x) x.Name, members, 'UniformOutput', false);
            Names = Names(~strcmp(Names, enums{i}.DefaultValue));
            % put member in UPPER case: Lustrec limitation
            names_in_order = [{enums{i}.DefaultValue}; Names];
            names_ast = cellfun(@(x) ...
                nasa_toLustre.lustreAst.EnumValueExpr(x), names_in_order, ...
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
        conds{i} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('x'), ...
            nasa_toLustre.lustreAst.EnumValueExpr(members{i}.Name));
        thens{i} = nasa_toLustre.lustreAst.IntExpr(members{i}.Value);
    end
    thens{end} = nasa_toLustre.lustreAst.IntExpr(0);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(strcat(name, '_to_int'));
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', name));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
function node = get_Int2Enum_conv_node(name, members)
        conds = cell(numel(members)-1, 1);
    thens = cell(numel(members), 1);
    for i=1:numel(members)-1
        conds{i} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('x'), ...
            nasa_toLustre.lustreAst.IntExpr(members{i}.Value));
        thens{i} = nasa_toLustre.lustreAst.EnumValueExpr(members{i}.Name);
    end
    thens{end} = nasa_toLustre.lustreAst.EnumValueExpr(members{end}.Name);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(strcat('int_to_', name));
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', name));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
