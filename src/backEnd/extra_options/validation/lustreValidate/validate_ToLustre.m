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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [res] = ...
        validate_ToLustre(orig_model_full_path, tests_method, model_checker, ...
        show_model, deep_CEX, min_max_constraints, options)
    
    
    validation_start = tic;
    res = struct();
    res.pp_VS_lustre_valid = -1;
    res.orig_VS_pp_valid = -1;
    res.orig_VS_pp_simulation_failed = -1;
    res.ToLustre_failed = -1;
    res.lustrec_failed = -1;
    res.lustrec_binary_failed= -1;
    res.pp_VS_lustre_simulation_failed = -1;
    res.validation_compute = -1;
    res.is_unsupported = 0;
    res.lus_file_path = '';
    res.orig_VS_pp_cex_file_path = '';
    res.pp_VS_lustre_cex_file_path = '';
    res.ir_json_path = '';
    %close all simulink models
    bdclose('all')
    %% define parameters if not given by the user
    [model_path, file_name, ~] = fileparts(char(orig_model_full_path));
    if ~exist('min_max_constraints', 'var') || isempty(min_max_constraints)
        min_max_constraints = coco_nasa_utils.SLXUtils.constructInportsMinMaxConstraints(orig_model_full_path, -300, 300);
    end
    
    if ~exist('deep_CEX', 'var') || isempty(deep_CEX)
        deep_CEX = 0;
    end
    if ~exist('tests_method', 'var') || isempty(tests_method)
        tests_method = 1;
    end
    if ~exist('model_checker', 'var') || isempty(model_checker)
        model_checker = 'KIND2';
    end
    if ~exist('options', 'var') || isempty(options)
        options = {};
    elseif ~iscell(options)
        new_opts{1} = options;
        options = new_opts;
    end
    if nargin < 3
        show_model = 0;
    end
    if show_model
        open(orig_model_full_path);
    else
        options{end+1} = nasa_toLustre.utils.ToLustreOptions.NODISPLAY;
    end
    
    stopAtPPValidation = ismember(coco_nasa_utils.CoCoBackendType.PP_VALIDATION, options);
    
    addpath(model_path);
    %% generate lustre code
    try
        f_msg = sprintf('Compiling model "%s" to Lustre\n',file_name);
        display_msg(f_msg, MsgType.RESULT, 'validation', '');
        
        [res.lus_file_path, xml_trace, res.ToLustre_failed, ...
            unsupportedOptions, ~, pp_model_full_path, res.ir_json_path] = ...
            nasa_toLustre.ToLustre(orig_model_full_path, [], coco_nasa_utils.LusBackendType.LUSTREC, ...
            coco_nasa_utils.CoCoBackendType.VALIDATION, options{:});
        res.is_unsupported = ~isempty(unsupportedOptions);
        if res.is_unsupported || res.ToLustre_failed
            display_msg('Model is not supported', MsgType.ERROR, 'validation', '');
            return;
        end
        [output_dir, ~, ~] = fileparts(res.lus_file_path);
        [~, model_file_name, ~] = fileparts(pp_model_full_path);
        file_name = model_file_name;
        main_node = model_file_name;
        if show_model
            open(pp_model_full_path);
        end
        
    catch ME
        msg = sprintf('Translation Failed for model "%s" :\n%s\n%s',...
            file_name,ME.identifier,ME.message);
        display_msg(msg, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        return;
    end
    
    %% for data types
    % no need in new compiler
    % BUtils.force_inports_DT(file_name);
    %% launch validation
    % validate pre-processing
    try
        [res.orig_VS_pp_valid, ...
            res.orig_VS_pp_simulation_failed, ...
            res.orig_VS_pp_cex_file_path] = ...
            coco_nasa_utils.SLXUtils.compareTwoSLXModels(orig_model_full_path, pp_model_full_path,...
            min_max_constraints, show_model);
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        return;
    end
    
    if stopAtPPValidation
        %TODO: add support for PP_validation of sub-components to easily
        %find the source of error.
        return;
    end
    try
        [res.pp_VS_lustre_valid, res.lustrec_failed,...
            res.lustrec_binary_failed, ...
            res.pp_VS_lustre_simulation_failed, ...
            res.pp_VS_lustre_cex_file_path] = ...
            compare_slx_lus(pp_model_full_path, res.lus_file_path, main_node, ...
            output_dir, tests_method, model_checker, show_model,...
            min_max_constraints, options);
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        return;
    end
    
    
    if res.pp_VS_lustre_valid~=1 && res.lustrec_failed~=1 && res.pp_VS_lustre_simulation_failed~=1 && res.lustrec_binary_failed~=1
        if show_model && deep_CEX <= 0
            prompt = 'The model is not valid. Do you want to check which subsystem is not valid? Y/N [N]: ';
            display_msg(prompt, MsgType.RESULT, 'validate_ToLustre', '');
            str = input('Type "Y" or "y" for yes or "N"|"n" for no: ','s');
            if ~isempty(str) && strcmpi(str, 'Y')
                prompt = 'Provide us with an integer that constrains the validation to a specific depth (1 for first depth only, n for up to n depth):';
                deep_CEX  = input(prompt);
                if ~isnumeric(deep_CEX)
                    display_msg('The answer should be a number', ...
                        MsgType.ERROR, 'validate_ToLustre', '');
                    deep_CEX = 0;
                end
            end
        end
        if  (deep_CEX > 0)
            %     validate_componentsV2(model_full_path, file_name, file_name, output_dir, ...
            %         deep_CEX, tests_method, model_checker, show_model, min_max_constraints, options);
            validate_components(pp_model_full_path, file_name, file_name, ...
                lus_file_path, xml_trace, output_dir, deep_CEX, 1, tests_method,...
                model_checker, 0, min_max_constraints, options);
        end
    end
    
    
    % close_system(model_full_path,0);
    % bdclose('all')
    
    if res.pp_VS_lustre_simulation_failed==1
        res.validation_compute = -1;
    else
        res.validation_compute = toc(validation_start);
    end
end


%%
function validate_components(file_path,file_name,block_path,  lus_file_path,...
        xml_trace, output_dir, deep_CEX, deep_current, tests_method, ...
        model_checker, show_model, min_max_constraints, options)
    ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
    if ~exist('deep_current', 'var')
        deep_current = 1;
    end
    for i=1:numel(ss)
        if strcmp(ss{i}, block_path)
            continue;
        end
        display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
        node_name = nasa_toLustre.utils.SLX2Lus_Trace.get_lustre_node_from_Simulink_block_name(xml_trace, ss{i});
        if ~strcmp(node_name, '')
            [new_model_path, ~, status] = coco_nasa_utils.SLXUtils.crete_model_from_subsystem(file_name, ss{i}, output_dir );
            if status
                continue;
            end
            try
                [valid, ~, ~, ~] = compare_slx_lus(new_model_path, lus_file_path,...
                    node_name, output_dir, tests_method, model_checker, ...
                    show_model, min_max_constraints, options);
                if ~valid
                    display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
                    load_system(file_path);
                    validate_components(file_path, file_name, ss{i}, lus_file_path,...
                        xml_trace, output_dir, deep_CEX, deep_current+1,...
                        tests_method, model_checker, show_model,...
                        min_max_constraints, options);
                    if deep_current > deep_CEX; return;end
                else
                    display_msg(['SubSystem ' ss{i} ' is valid'], MsgType.RESULT, 'validation', '');
                end
            catch ME
                display_msg(ME.message, MsgType.ERROR, 'validation', '');
                display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
                rethrow(ME);
            end
        else
            display_msg(['No node for subsytem ' ss{i} ' is found'], MsgType.INFO, 'validation', '');
        end
    end
    
end


%% This version creates a new model from subsystem and start validation process again.
function validate_componentsV2(file_path, file_name, block_path, output_dir, ...
        deep_CEX, tests_method, model_checker, show_model, min_max_constraints, options)
    % This version re-translate the subsystem to Lustre and does not take
    % advantage from traceability. Because the lustre generated has additional
    % inputs (like _timpe_step) so the signature of the lustre node is
    % different from the Subsystem.
    ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
    [~, mdl_name, ~] = fileparts(file_path);
    if numel(ss) == 1
        ss = find_system(ss{1}, 'SearchDepth',1, 'BlockType','SubSystem');
        ss = ss(2:end);
    end
    for i=1:numel(ss)
        if strcmp(ss{i}, block_path)
            continue;
        end
        display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
        if ~bdIsLoaded(mdl_name),load_system(file_path);end
        [new_model_path, ~, status] = coco_nasa_utils.SLXUtils.crete_model_from_subsystem(file_name, ss{i}, output_dir );
        if status
            continue;
        end
        try
            valid = validate_ToLustre(new_model_path, tests_method, model_checker, ...
                show_model, deep_CEX-1, min_max_constraints, options);
            if valid == 0
                display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
            elseif valid == 1
                display_msg(['SubSystem ' ss{i} ' is valid'], MsgType.RESULT, 'validation', '');
            elseif valid == -1
                display_msg(['Validation of ' ss{i} ' has failed'], MsgType.RESULT, 'validation', '');
            end
        catch ME
            display_msg(ME.message, MsgType.ERROR, 'validation', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
            rethrow(ME);
        end
        
    end
    
end
