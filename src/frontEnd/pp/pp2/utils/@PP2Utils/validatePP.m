function [pp_valid, pp_sim_failed, pp_failed] = validatePP(orig_model_full_path, options)
    if nargin < 2
        options = {};
    end
    try
        [pp_model_full_path, pp_failed] = cocosim_pp(orig_model_full_path, options{:});
        if pp_failed
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
    catch ME
        display_msg('Pre-processing validation failed', MsgType.ERROR, 'PP2Utils.validatePP', '');
        display_msg(ME.message, MsgType.ERROR, 'PP2Utils.validatePP', '');
        display_msg(ME.getReport(), MsgType.ERROR, 'PP2Utils.validatePP', '');
        pp_valid = -1;
        pp_sim_failed = -1;
    end
end
