%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the 
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
%function [status, errors_msg] = DetectorSLDV_pp(model)
% DetectorSLDV_pp Searches for Detector blocks from SLDV library 
% and replaces them by a PP-friendly equivalent.
%   model is a string containing the name of the model to search in
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
            if strcmp(reset, 'off')
                suffix = 'ResetFalse';
            else
                suffix = 'ResetTrue';
            end
            if strcmp(typ, 'Delayed Fixed Duration')
                pp_name = strcat('Detector_DelayedFixedDuration', suffix);
            else
                pp_name = strcat('Detector_Synchronized', suffix);
            end
            
            NASAPPUtils.replace_one_block(detector_list{i},fullfile('pp_lib',pp_name));
            set_param(detector_list{i},'in_hold', in_hold);
            if strcmp(typ, 'Delayed Fixed Duration')
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

