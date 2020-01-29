function [pp_valid, pp_sim_failed, cocosim_pp_failed] = validatePP(orig_model_full_path, options, output_dir)
    if nargin < 2
        options = {};
    end
    if ~ismember(nasa_toLustre.utils.ToLustreOptions.SKIP_DEFECTED_PP, options)
        options{end+1} = nasa_toLustre.utils.ToLustreOptions.SKIP_DEFECTED_PP;
    end
    validateSubcomponents = ismember('validateSubcomponents', options);
    try
        [pp_model_full_path, cocosim_pp_failed] = cocosim_pp(orig_model_full_path, options{:});
        if cocosim_pp_failed
            pp_valid = 0;
            pp_sim_failed = 0;
        elseif strcmp(pp_model_full_path, orig_model_full_path)
            % same model
            pp_valid = 1;
            pp_sim_failed = 0;
        else
            [pp_valid, pp_sim_failed] = ...
                SLXUtils.compareTwoSLXModels(orig_model_full_path, pp_model_full_path);
        end
        if validateSubcomponents && ~pp_valid && ~pp_sim_failed
            if nargin < 3
                [mdl_dir, mdl_name, ~] = fileparts(orig_model_full_path);
                output_dir = fullfile(mdl_dir, 'cocosim_output', mdl_name);
                MatlabUtils.mkdir(output_dir);
            end
            validate_components(orig_model_full_path, output_dir, options);
        end
    catch ME
        display_msg('Pre-processing validation failed', MsgType.ERROR, 'NASAPPUtils.validatePP', '');
        display_msg(ME.message, MsgType.ERROR, 'NASAPPUtils.validatePP', '');
        display_msg(ME.getReport(), MsgType.ERROR, 'NASAPPUtils.validatePP', '');
        pp_valid = -1;
        pp_sim_failed = -1;
    end
    
end


function validate_components(orig_model_full_path, output_dir, options)
    [~, mdl_name, ~] = fileparts(orig_model_full_path);
    ss = find_system(mdl_name, 'SearchDepth',1, 'BlockType','SubSystem');
    
    for i=1:numel(ss)
        display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
        [new_model_path, ~, status] = SLXUtils.crete_model_from_subsystem(...
            mdl_name, ss{i}, output_dir );
        if status
            continue;
        end
        try
            [pp_valid, pp_sim_failed, cocosim_pp_failed] = ...
                NASAPPUtils.validatePP(new_model_path, options, output_dir);
            if ~pp_valid && ~pp_sim_failed && ~cocosim_pp_failed
                display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], ...
                    MsgType.RESULT, 'validation', '');
            elseif pp_valid
                display_msg(['SubSystem ' ss{i} ' is valid'],...
                    MsgType.RESULT, 'validation', '');
            end
        catch ME
            display_msg(ME.message, MsgType.ERROR, 'validation', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
            rethrow(ME);
        end
        
    end
    
end
