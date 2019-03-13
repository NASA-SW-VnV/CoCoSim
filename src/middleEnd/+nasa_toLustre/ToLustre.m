function [lustre_file_path, xml_trace, failed, unsupportedOptions, abstractedBlocks, pp_model_full_path]= ...
        ToLustre(model_path, const_files, lus_backend, coco_backend, varargin)
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
    %
    %
    
    %% global variables
    global TOLUSTRE_ENUMS_MAP TOLUSTRE_ENUMS_CONV_NODES ...
        KIND2 Z3 JLUSTRE2KIND LUSTREC CHECK_SF_ACTIONS ...
        ERROR_MSG WARNING_MSG DEBUG_MSG COCOSIM_DEV_DEBUG...
        DED_PROP_MAP CoCoSimPreferences;
    ERROR_MSG = {};
    WARNING_MSG = {};
    DEBUG_MSG = {};
    if isempty(LUSTREC) || isempty(KIND2)
        tools_config;
    end
    TOLUSTRE_ENUMS_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
    TOLUSTRE_ENUMS_CONV_NODES = {};
    % This map takes as keys the Properties ID and as value the type of check
    % and the path to the block under check.
    DED_PROP_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    try
        COCOSIM_DEV_DEBUG = evalin('base','cocosim_debug_dev');
    catch
        COCOSIM_DEV_DEBUG  = false;
    end
    %% Get start time
    t_start = tic;
    
    %% inputs treatment
    narginchk(1,inf);
    if nargin < 2 || isempty(const_files)
        const_files = {};
    end
    if nargin < 3 || isempty(lus_backend)
        lus_backend = CoCoSimPreferences.lustreBackend;
    end
    if nargin < 4 || isempty(coco_backend)
        coco_backend = CoCoBackendType.VALIDATION;
    end
    try
        forceGeneration = evalin('base', nasa_toLustre.utils.ToLustreOptions.FORCE_CODE_GEN);
    catch
        forceGeneration = 0;
    end
    mode_display = 1;
    try
        skip_sf_actions_check = evalin('base', nasa_toLustre.utils.ToLustreOptions.SKIP_SF_ACTIONS_CHECK);
        CHECK_SF_ACTIONS = ~skip_sf_actions_check;
    catch
        CHECK_SF_ACTIONS = 1;
    end
    try
        cocosim_optim = ~evalin('base', nasa_toLustre.utils.ToLustreOptions.SKIP_CODE_OPTIMIZATION);
    catch
        cocosim_optim = true;
    end
    for i=1:numel(varargin)
        if strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.NODISPLAY)
            mode_display = 0;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.FORCE_CODE_GEN)
            forceGeneration = 1;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.SKIP_SF_ACTIONS_CHECK)
            CHECK_SF_ACTIONS = 0;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.SKIP_CODE_OPTIMIZATION)
            cocosim_optim = false;
        end
    end
    %% initialize outputs
    lustre_file_path = '';
    xml_trace = [];
    failed = 0;
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
        ToLustre_datenum_map = containers.Map('KeyType', 'char', ...
            'ValueType', 'char');
    end
    if ~forceGeneration && isKey(ToLustre_datenum_map, model_path)
        lustre_file_path = ToLustre_datenum_map(model_path);
        % get the name of lustre file with the given backend
        [output_dir, lus_fname, ~] = fileparts(lustre_file_path);
        [lustre_file_path, mat_file] = ...
            nasa_toLustre.utils.SLX2LusUtils.getLusOutputPath(output_dir, ...
            MatlabUtils.fileBase(lus_fname), lus_backend);
        if exist(lustre_file_path, 'file') ...
                && BUtils.isLastModified(model_path, lustre_file_path) ...
                && exist(mat_file, 'file')
                M = load(mat_file);
                if exist(M.pp_model_full_path, 'file') ...
                        && BUtils.isLastModified(M.pp_model_full_path, ...
                        lustre_file_path)
                    xml_trace = M.xml_trace;
                    failed = M.failed;
                    unsupportedOptions = M.unsupportedOptions;
                    abstractedBlocks = M.abstractedBlocks;
                    pp_model_full_path = M.pp_model_full_path;
                    display_msg(['Skipping Lustre generation step. ', ...
                        'Using previously generated code, no modifications '..., 
                        'have been made to the model.'],...
                        MsgType.RESULT, 'ToLustre', '');
                    return;
                end
            
        end
    end
    
    
    try
        [unsupportedOptions, failed, pp_model_full_path, ir_struct, ...
            output_dir, abstractedBlocks]= ...
            nasa_toLustre.ToLustreUnsupportedBlocks(model_path, const_files, lus_backend, ...
            coco_backend, varargin{:});
        
        if ~forceGeneration && (failed || ~isempty(unsupportedOptions))
            failed = true;
            return;
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'ToLustre', '');
        failed = 1;
        return;
    end
    [~, file_name, ~] = fileparts(pp_model_full_path);
    %% Definition of the generated output files names
    [lustre_file_path, mat_file] = ...
        nasa_toLustre.utils.SLX2LusUtils.getLusOutputPath(output_dir, file_name, lus_backend);
    %% Create Meta informations
    create_file_meta_info(lustre_file_path);
    
    %% Create traceability informations in XML format
    display_msg('Start tracebility', MsgType.INFO, 'lustre_multiclocks_compiler', '');
    xml_trace_file_name = fullfile(output_dir, strcat(file_name, '.toLustre.trace.xml'));
    json_trace_file_name = fullfile(output_dir, strcat(file_name, '_mapping.json'));
    xml_trace = nasa_toLustre.utils.SLX2Lus_Trace(pp_model_full_path,...
        xml_trace_file_name, json_trace_file_name);
    
    
    
    %% Lustre generation
    display_msg('Lustre generation', Constants.INFO, 'lustre_multiclocks_compiler', '');
    % add enumeration nodes
    % Lustre code
    global model_struct
    model_struct = ir_struct.(IRUtils.name_format(file_name));
    main_sampleTime = model_struct.CompiledSampleTime;
    is_main_node = 1;
    [nodes_ast, contracts_ast, external_libraries, failed] = recursiveGeneration(...
        model_struct, model_struct, main_sampleTime, is_main_node, lus_backend, coco_backend, xml_trace);
    if ~forceGeneration && failed
        html_path = fullfile(output_dir, strcat(file_name, '_error_messages.html'));
        %HtmlItem.displayErrorMessages(html_path, ERROR_MSG, mode_display);
        HtmlItem.display_LOG_Messages(html_path, ...
            ERROR_MSG, WARNING_MSG, DEBUG_MSG, mode_display);
        if mode_display
            msg = sprintf('ERRORS report is in : %s', html_path);
            display_msg(msg, MsgType.ERROR, 'ToLustre', '');
        end
        return;
    end
    [external_lib_code, open_list, abstractedNodes] = nasa_toLustre.utils.getExternalLibrariesNodes(external_libraries, lus_backend);
    abstractedBlocks = [abstractedBlocks, abstractedNodes];
    
    %TODO: change it to AST
    if ~isempty(external_lib_code)
        nodes_ast = [external_lib_code, nodes_ast];
    end
    %% create LustreProgram
    
    keys = TOLUSTRE_ENUMS_MAP.keys();
    enumsAst = cell(numel(keys), 1);
    for i=1:numel(keys)
        enumsAst{i} = nasa_toLustre.lustreAst.EnumTypeExpr(keys{i}, TOLUSTRE_ENUMS_MAP(keys{i}));
    end
    if ~isempty(TOLUSTRE_ENUMS_CONV_NODES)
        nodes_ast = [TOLUSTRE_ENUMS_CONV_NODES, nodes_ast];
    end
    nodes_ast = MatlabUtils.removeEmpty(nodes_ast);
    contracts_ast = MatlabUtils.removeEmpty(contracts_ast);
    program =  nasa_toLustre.lustreAst.LustreProgram(open_list, enumsAst, nodes_ast, contracts_ast);
    if cocosim_optim ...
            && ~(LusBackendType.isLUSTREC(lus_backend) || LusBackendType.isZUSTRE(lus_backend))
        % Optimization is not important for Lustrec as the later normalize all expressions. 
        try program = program.simplify(); catch me, display_msg(me.getReport(), MsgType.DEBUG, 'ToLustre.simplify', ''); end
    end
    % copy Kind2 libraries
    if LusBackendType.isKIND2(lus_backend)
        if ismember('lustrec_math', open_list)
            lib_path = fullfile(fileparts(mfilename('fullpath')),...
                '+lib', 'lustrec_math.lus');
            copyfile(lib_path, output_dir);
        end
        if ismember('simulink_math_fcn', open_list)
            lib_path = fullfile(fileparts(mfilename('fullpath')),...
                '+lib', 'simulink_math_fcn.lus');
            copyfile(lib_path, output_dir);
        end
    end
    %% writing code
    fid = fopen(lustre_file_path, 'a');
    if fid==-1
        msg = sprintf('Opening file "%s" is not possible', lustre_file_path);
        display_msg(msg, MsgType.ERROR, 'lustre_multiclocks_compiler', '');
    end
    try
        Lustrecode = program.print(lus_backend);
        fprintf(fid, '%s', Lustrecode);
        fclose(fid);
        if COCOSIM_DEV_DEBUG
            display_msg(strrep(Lustrecode, '%', '%%'), MsgType.DEBUG, ...
                'lustre_multiclocks_compiler', '');
        end
    catch me
        display_msg('Printing Lustre AST to file failed',...
            MsgType.ERROR, 'write_body', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
        failed = 1;
        return;
    end
    
    
    %% writing traceability
    xml_trace.write();
    
    %% save results in mat file.
    save(mat_file, 'xml_trace', 'failed', 'unsupportedOptions', 'abstractedBlocks', 'pp_model_full_path');
    ToLustre_datenum_map(model_path) = lustre_file_path;
    
    %% check lustre syntax
    if ~LusBackendType.isPRELUDE(lus_backend) 
        if LusBackendType.isKIND2(lus_backend)
            [syntax_status, output] = Kind2Utils2.checkSyntaxError(lustre_file_path, KIND2, Z3);
        elseif LusBackendType.isLUSTREC(lus_backend)
            [~, syntax_status, output] = LustrecUtils.generate_lusi(lustre_file_path, LUSTREC );
        elseif LusBackendType.isJKIND(lus_backend)
            [syntax_status, output] = JKindUtils.checkSyntaxError(lustre_file_path, JLUSTRE2KIND);
        else
            syntax_status = 0;
            output = '';
        end
        if syntax_status && ~isempty(output)
            display_msg('Simulink To Lustre Syntax check has failed. The parsing error is the following:', MsgType.ERROR, 'TOLUSTRE', '');
            [~, lustre_file_base, ~] = fileparts(lustre_file_path);
            output = regexprep(output, lustre_file_path, HtmlItem.addOpenFileCmd(lustre_file_path, lustre_file_base));
            display_msg(output, MsgType.ERROR, 'TOLUSTRE', '');
            failed = syntax_status;
        else
            display_msg('Simulink To Lustre Syntax check passed successfully.', MsgType.RESULT, 'TOLUSTRE', '');
        end
        failed = syntax_status;
    end
    if ~isempty(ERROR_MSG)
        f_base =strcat(file_name, '_error_messages.html');
        html_path = fullfile(output_dir, f_base);
        %HtmlItem.displayErrorMessages(html_path, ERROR_MSG, mode_display);
        HtmlItem.display_LOG_Messages(html_path, ...
            ERROR_MSG, WARNING_MSG, DEBUG_MSG, mode_display);
        if mode_display
            msg = sprintf('ERRORS report is in : %s', HtmlItem.addOpenFileCmd(html_path, f_base));
            display_msg(msg, MsgType.ERROR, 'ToLustre', '');
        end
        
    end
    %% REPORT ABSTRACTED BLOCKS
    if ~isempty(abstractedBlocks)
        f_base = strcat(file_name, '_abstracted_blocks.html');
        html_path = fullfile(output_dir, f_base);
        HtmlItem.displayWarningMessages(html_path, 'The following Blocks/Nodes are abstracted', abstractedBlocks, mode_display);
        if mode_display
            msg = sprintf('Abstracted blocks report is in : %s', HtmlItem.addOpenFileCmd(html_path, f_base));
            display_msg(msg, MsgType.RESULT, 'ToLustre', '');
        end
    end
    %% display report files
    t_finish = toc(t_start);
    
    msg = sprintf('Lustre File generated:%s', lustre_file_path);
    display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');
    msg = sprintf('Lustre generation finished in %f seconds', t_finish);
    display_msg(msg, MsgType.RESULT, 'lustre_multiclocks_compiler', '');
    
    
end

%%
function [nodes_ast, contracts_ast, external_libraries, error_status] = ...
        recursiveGeneration(parent, blk, main_sampleTime, is_main_node,...
        lus_backend, coco_backend, xml_trace)
        nodes_ast = {};
    contracts_ast = {};
    external_libraries = {};
    error_status = false;
    if isfield(blk, 'Content') && ~isempty(blk.Content) ...
            && ~(isstruct(blk.Content) && isempty(fieldnames(blk.Content)))
        field_names = fieldnames(blk.Content);
        for i=1:numel(field_names)
            
            [nodes_code_i, contracts_ast_i, external_libraries_i, error_status_i] = ...
                recursiveGeneration(blk, blk.Content.(field_names{i}),...
                main_sampleTime, 0, lus_backend, coco_backend, xml_trace);
            if ~isempty(nodes_code_i)
                nodes_ast = [ nodes_ast, nodes_code_i];
            end
            if ~isempty(contracts_ast_i)
                contracts_ast = [ contracts_ast, contracts_ast_i];
            end
            external_libraries = [external_libraries, external_libraries_i];
            error_status = error_status_i || error_status;
        end
        [b, status] = nasa_toLustre.utils.getWriteType(blk);
        if status || ~b.isContentNeedToBeTranslated()
            return;
        end
        try
            [main_node, is_contract, external_nodes, external_libraries_i] ...
                = nasa_toLustre.frontEnd.SS_To_LustreNode.subsystem2node(parent, blk, main_sampleTime, ...
                is_main_node, lus_backend, coco_backend, xml_trace);
        catch me
            display_msg(sprintf('Translation to Lustre of block %s has failed.', HtmlItem.addOpenCmd(blk.Origin_path)),...
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
    
    end
end


%%
function create_file_meta_info(lustre_file)
    % Create lustre file
    fid = fopen(lustre_file, 'w');
    text = '-- This file has been generated by CoCoSim2.\n\n';
    text = [text, '-- Compiler: Lustre compiler 2 (nasa_toLustre.ToLustre.m)\n'];
    text = [text, '-- Time: ', char(datetime), '\n'];
    fprintf(fid, text);
    fclose(fid);
end

