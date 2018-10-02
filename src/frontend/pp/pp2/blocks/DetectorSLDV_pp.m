function [status, errors_msg] = DetectorSLDV_pp(model)
% DetectorSLDV_pp Searches for Detector blocks from SLDV library 
% and replaces them by a PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Detector blocks
status = 0;
errors_msg = {};

detector_list = find_system(model, ...
    'LookUnderMasks', 'all', 'MaskType','Detector');
if not(isempty(detector_list))
    display_msg('Replacing Detector blocks...', MsgType.INFO,...
        'DetectorSLDV_pp', '');
    for i=1:length(detector_list)
        try
            display_msg(detector_list{i}, MsgType.INFO, ...
                'DetectorSLDV_pp', '');
            reset = get_param(detector_list{i},'reset');
            typ = get_param(detector_list{i},'typ');
            in_hold = get_param(detector_list{i},'in_hold');
            delay = get_param(detector_list{i},'delay');
            out_hold = get_param(detector_list{i},'out_hold');
            if isequal(reset, 'off')
                suffix = 'ResetFalse';
            else
                suffix = 'ResetTrue';
            end
            if isequal(typ, 'Delayed Fixed Duration')
                pp_name = strcat('Detector_DelayedFixedDuration', suffix);
            else
                pp_name = strcat('Detector_Synchronized', suffix);
            end
            
            replace_one_block(detector_list{i},fullfile('pp_lib',pp_name));
            set_param(detector_list{i}, 'LinkStatus', 'inactive');
            set_param(detector_list{i},'in_hold', in_hold);
            if isequal(typ, 'Delayed Fixed Duration')
                set_param(detector_list{i},'delay', delay);
                set_param(detector_list{i},'out_hold', out_hold);
            end
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('DetectorSLDV_pp pre-process has failed for block %s', detector_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'DetectorSLDV_pp', '');
end

end

