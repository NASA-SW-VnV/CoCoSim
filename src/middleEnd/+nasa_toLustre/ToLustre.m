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
function [lustre_file_path, xml_trace, failed, unsupportedOptions, ...
        abstractedBlocks, pp_model_full_path, ir_json_path]= ...
        ToLustre(model_path, const_files, lus_backend, coco_backend, varargin)
    %ToLustre translate Simulink models to Lustre. It is based on
    %article :
    %INPUTS:
    %   MODEL_PATH: The full path of the Simulink model.
    %   CONST_FILES: The list of constant files to be run in order to be able
    %   to simulate the simulink model.
    %   MODE_DISPLAY: equals to 0 if no display wanted, equals to 1 if the user
    %   want the Simulink model to be open.

    %
    %
    
    %% global variables
    global TOLUSTRE_ENUMS_MAP TOLUSTRE_ENUMS_CONV_NODES ...
        KIND2 Z3 JLUSTRE2KIND LUSTREC LUCTREC_INCLUDE_DIR CHECK_SF_ACTIONS ...
        ERROR_MSG WARNING_MSG DEBUG_MSG COCOSIM_DEV_DEBUG...
        DED_PROP_MAP CoCoSimPreferences ir_handle_struct_map...
        TOLUSTRE_TIME_STEP_ASTEQ TOLUSTRE_NB_STEP_ASTEQ;
    ERROR_MSG = {};
    WARNING_MSG = {};
    DEBUG_MSG = {};
    if isempty(LUSTREC) || isempty(KIND2)
        tools_config;
    end
    ir_handle_struct_map = containers.Map('KeyType','double', 'ValueType','any');
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
        coco_backend = coco_nasa_utils.CoCoBackendType.VALIDATION;
    end
    try
        forceGeneration = evalin('base', nasa_toLustre.utils.ToLustreOptions.FORCE_CODE_GEN);
    catch
        forceGeneration = CoCoSimPreferences.forceCodeGen;
    end
    mode_display = 1;
    try
        skip_sf_actions_check = evalin('base', nasa_toLustre.utils.ToLustreOptions.SKIP_SF_ACTIONS_CHECK);
        CHECK_SF_ACTIONS = ~skip_sf_actions_check;
    catch
        CHECK_SF_ACTIONS = ~CoCoSimPreferences.skip_sf_actions_check;
    end
    try
        cocosim_optim = ~evalin('base', nasa_toLustre.utils.ToLustreOptions.SKIP_CODE_OPTIMIZATION);
    catch
        cocosim_optim = ~CoCoSimPreferences.skip_optim;
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
    ir_json_path = '';
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
            coco_nasa_utils.MatlabUtils.fileBase(lus_fname), lus_backend);
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
                    if isfield(M, 'ir_json_path')
                        ir_json_path = M.ir_json_path;
                    end
                    display_msg(['Skipping Lustre generation step. ', ...
                        'Using previously generated code, no modifications '..., 
                        'have been made to the model.'],...
                        MsgType.RESULT, 'ToLustre', '');
                    display_msg(sprintf('If you want to force code generation set "%s" to 1 in Matlab workspace', ...
                        nasa_toLustre.utils.ToLustreOptions.FORCE_CODE_GEN),...
                        MsgType.RESULT, 'ToLustre', '');
                    return;
                end
            
        end
    end
    
    
    try
        [unsupportedOptions, failed, pp_model_full_path, ir_struct, ...
            output_dir, abstractedBlocks, ir_json_path]= ...
            nasa_toLustre.ToLustreUnsupportedBlocks(model_path, const_files, lus_backend, ...
            coco_backend, varargin{:});
        
        if ~forceGeneration && (failed || ~isempty(unsupportedOptions))
            failed = true;
            display_msg('Model is not supported. See errors above.', MsgType.ERROR, 'ToLustre', '');
            return;
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'ToLustre', '');
        failed = 1;
        display_msg('Model is not supported. See errors above.', MsgType.ERROR, 'ToLustre', '');
        return;
    end
    if failed
        display_msg('Model is not supported. See errors above.', MsgType.ERROR, 'ToLustre', '');
        return;
    end
    [~, file_name, ~] = fileparts(pp_model_full_path);
    %% Definition of the generated output files names
    [lustre_file_path, mat_file, plu_path] = ...
        nasa_toLustre.utils.SLX2LusUtils.getLusOutputPath(output_dir, file_name, lus_backend);
    %% Create Meta informations
    create_file_meta_info(lustre_file_path);
    if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend)
        create_file_meta_info(plu_path);
    end
    %% Create traceability informations in XML format
    display_msg('Start tracebility', MsgType.INFO, 'ToLustre', '');
    xml_trace_file_name = fullfile(output_dir, strcat(file_name, '.toLustre.trace.xml'));
    json_trace_file_name = fullfile(output_dir, strcat(file_name, '_mapping.json'));
    xml_trace = nasa_toLustre.utils.SLX2Lus_Trace(pp_model_full_path,...
        xml_trace_file_name, json_trace_file_name);
    
    
    
    %% Lustre generation
    display_msg('Lustre generation', Constants.INFO, 'ToLustre', '');
    % add enumeration nodes
    % Lustre code
    global model_struct
    main_fieldName = IRUtils.name_format(file_name);
    if ~isfield(ir_struct, main_fieldName)
        display_msg(...
            sprintf('Internal structure of the model has no field called "%s". Translation will be terminated.', main_fieldName),...
            MsgType.ERROR, 'ToLustre', '');
        failed = 1;
        return;
    end
    model_struct = ir_struct.(main_fieldName);
    main_sampleTime = model_struct.CompiledSampleTime;
    external_libraries = {};
    if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend)
        % no computation is allowed in prelude file
        external_libraries{end+1} = 'getNbStep';
        external_libraries{end+1} = 'getTimeStep';
        TOLUSTRE_TIME_STEP_ASTEQ = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr()), ...
            nasa_toLustre.lustreAst.NodeCallExpr('getTimeStep', ...
            {nasa_toLustre.lustreAst.RealExpr(main_sampleTime(1))}));
        TOLUSTRE_NB_STEP_ASTEQ = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), ...
            nasa_toLustre.lustreAst.NodeCallExpr('getNbStep', ...
            {nasa_toLustre.lustreAst.BoolExpr(true)}));
    else
        TOLUSTRE_TIME_STEP_ASTEQ = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr()), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            nasa_toLustre.lustreAst.RealExpr('0.0'), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr())), ...
            nasa_toLustre.lustreAst.RealExpr(main_sampleTime(1)))));
        TOLUSTRE_NB_STEP_ASTEQ = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            nasa_toLustre.lustreAst.IntExpr('0'), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr())), ...
            nasa_toLustre.lustreAst.IntExpr('1'))));
    end
    is_main_node = 1;
    [nodes_ast, contracts_ast, external_libraries_i, abstractedBlocks_i, failed] = recursiveGeneration(...
        model_struct, model_struct, main_sampleTime, is_main_node, lus_backend, coco_backend, xml_trace);
    external_libraries = coco_nasa_utils.MatlabUtils.concat(external_libraries, external_libraries_i);
    abstractedBlocks = [abstractedBlocks, abstractedBlocks_i];
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
    nodes_ast = coco_nasa_utils.MatlabUtils.removeEmpty(nodes_ast);
    contracts_ast = coco_nasa_utils.MatlabUtils.removeEmpty(contracts_ast);
    program =  nasa_toLustre.lustreAst.LustreProgram(open_list, enumsAst, nodes_ast, contracts_ast);
    if cocosim_optim %...
            % && ~(coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend) || coco_nasa_utils.LusBackendType.isZUSTRE(lus_backend))
        % Optimization is not important for Lustrec as the later normalize all expressions. 
        try program = program.simplify(); catch me, display_msg(me.getReport(), MsgType.DEBUG, 'ToLustre.simplify', ''); end
    end
    
    %% writing code
    lus_fid = fopen(lustre_file_path, 'a');
    if lus_fid==-1
        msg = sprintf('Opening file "%s" is not possible', lustre_file_path);
        display_msg(msg, MsgType.ERROR, 'ToLustre', '');
        failed = 1;
        return;
    end
    if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend)
        plu_fid = fopen(plu_path, 'a');
        if plu_fid==-1
            msg = sprintf('Opening file "%s" is not possible', plu_path);
            display_msg(msg, MsgType.ERROR, 'ToLustre', '');
            failed = 1;
            return;
        end
    end
    try
        [lustrecode, preludeCode, ext_lib] = program.print(lus_backend);
        open_list = coco_nasa_utils.MatlabUtils.concat(open_list, ext_lib);
        fprintf(lus_fid, '%s', lustrecode);
        fclose(lus_fid);
        if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend)
            fprintf(plu_fid, '%s', preludeCode);
            fclose(plu_fid);
        end
        if COCOSIM_DEV_DEBUG
            display_msg(strrep(lustrecode, '%', '%%'), MsgType.DEBUG, ...
                'ToLustre', '', 3);
            if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend)
                display_msg('*****PRELUDE CODE *******', MsgType.DEBUG, ...
                'ToLustre', '');
                display_msg(strrep(preludeCode, '%', '%%'), MsgType.DEBUG, ...
                    'ToLustre', '', 3);
            end
        end
    catch me
        display_msg('Printing Lustre AST to file failed',...
            MsgType.ERROR, 'write_body', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
        failed = 1;
        return;
    end
    
    %% copy Kind2 libraries
    if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
        toLustrePath = fileparts(mfilename('fullpath'));
        % lustrec_math
        if ismember('lustrec_math', open_list)
            lib_name = 'lustrec_math.lus';
            if CoCoSimPreferences.use_more_precise_abstraction
                lib_name = 'lustrec_math_more_precise_abstraction.lus';
                open_list{strcmp(open_list, 'lustrec_math')} = 'lustrec_math_more_precise_abstraction';
            end
            lib_path = fullfile(toLustrePath, '+lib', lib_name);
            copyfile(lib_path, output_dir);
        end
        
        % simulink_math_fcn
        if ismember('simulink_math_fcn', open_list)
            lib_path = fullfile(toLustrePath, '+lib', 'simulink_math_fcn.lus');
            copyfile(lib_path, output_dir);
        end
        
        % conv
        if ismember('conv', open_list)
            lib_path = fullfile(toLustrePath, '+lib', 'conv.lus');
            copyfile(lib_path, output_dir);
        end
        
        % kind2_lib
        if ismember('kind2_lib', open_list)
            lib_path = fullfile(toLustrePath, '+lib', 'kind2_lib.lus');
            copyfile(lib_path, output_dir);
        end
    else %lustrec, zustre ... 
        % This fix is not needed for lustrec unstable branch. It should be
        % fixed in lustrec-seal branch as well
%         if ismember('simulink_math_fcn', open_list) ...
%                 && ismember('lustrec_math', open_list)
%             simulink_math_fcn_path = fullfile(LUCTREC_INCLUDE_DIR, ...
%                 'simulink_math_fcn.lusi');
%             if exist(simulink_math_fcn_path, 'file')
%                 ftext = fileread(simulink_math_fcn_path);
%                 if coco_nasa_utils.MatlabUtils.contains(ftext, 'open <lustrec_math>')
%                     % simulink_math_fcn includes lustrec_math, so remove
%                     % lustrec_math to avoid double definition of functions
%                     % error
%                     open_list = open_list(~strcmp(open_list, 'lustrec_math'));
%                 end
%             end
%         end
    end
    %% writing traceability
    xml_trace.write();
    
    %% save results in mat file.
    save(mat_file, 'xml_trace', 'failed', 'unsupportedOptions', 'abstractedBlocks', 'pp_model_full_path', 'ir_json_path');
    ToLustre_datenum_map(model_path) = lustre_file_path;
    
    %% check lustre syntax
    if ~coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend) 
        if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
            [syntax_status, output] = Kind2Utils2.checkSyntaxError(lustre_file_path, KIND2, Z3);
        elseif coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend)
            [~, syntax_status, output] = LustrecUtils.generate_lusi(lustre_file_path, LUSTREC );
        elseif coco_nasa_utils.LusBackendType.isJKIND(lus_backend)
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
    display_msg(msg, MsgType.RESULT, 'ToLustre', '');
    if coco_nasa_utils.LusBackendType.isPRELUDE(lus_backend)
        msg = sprintf('PRELUDE File generated:%s', plu_path);
        display_msg(msg, MsgType.RESULT, 'ToLustre', '');
    end
    msg = sprintf('Lustre generation finished in %f seconds', t_finish);
    display_msg(msg, MsgType.RESULT, 'ToLustre', '');
    
    
end

%%
function [nodes_ast, contracts_ast, external_libraries, abstractedBlocks, error_status] = ...
        recursiveGeneration(parent, blk, main_sampleTime, is_main_node,...
        lus_backend, coco_backend, xml_trace)
        nodes_ast = {};
    contracts_ast = {};
    external_libraries = {};
    abstractedBlocks = {};
    error_status = false;
    if isfield(blk, 'Content') && ~isempty(blk.Content) ...
            && ~(isstruct(blk.Content) && isempty(fieldnames(blk.Content)))
        field_names = fieldnames(blk.Content);
        for i=1:numel(field_names)
            
            [nodes_code_i, contracts_ast_i, external_libraries_i, abstractedBlocks_i, ...
                error_status_i] = ...
                recursiveGeneration(blk, blk.Content.(field_names{i}),...
                main_sampleTime, 0, lus_backend, coco_backend, xml_trace);
            if ~isempty(nodes_code_i)
                nodes_ast = [ nodes_ast, nodes_code_i];
            end
            if ~isempty(contracts_ast_i)
                contracts_ast = [ contracts_ast, contracts_ast_i];
            end
            external_libraries = [external_libraries, external_libraries_i];
            abstractedBlocks = [abstractedBlocks, abstractedBlocks_i];
            error_status = error_status_i || error_status;
        end
        [b, status] = nasa_toLustre.utils.getWriteType(blk, lus_backend);
        if status || ~b.isContentNeedToBeTranslated()
            return;
        end
        try
            [main_node, is_contract, external_nodes, external_libraries_i, abstractedBlocks_i] ...
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
        abstractedBlocks = [abstractedBlocks, abstractedBlocks_i];
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

