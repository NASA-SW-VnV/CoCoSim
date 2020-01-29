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
%function [status, errors_msg] = Saturation_pp(model)
% SATURATION_PP changes Saturation block to Min/Max blocks.
% if Upper limit or Lower limit are Infinite "Inf" they are ignored.

status = 0;
errors_msg = {};

saturation_list = find_system(model,'BlockType','Saturate');
if ~ ( isempty( saturation_list ) )
    display_msg('Processing Saturation blocks...', Constants.INFO,...
        'Saturation_pp', '');
    for i=1:length(saturation_list)
        display_msg(saturation_list{i}, Constants.INFO, ...
            'Saturation_pp', '');
        try
            lower_limit = get_param(saturation_list{i},'LowerLimit');
            upper_limit = get_param(saturation_list{i},'UpperLimit');
            outputDataType = get_param(saturation_list{i}, 'OutDataTypeStr');
            OutMin = get_param(saturation_list{i}, 'OutMin');
            OutMax = get_param(saturation_list{i}, 'OutMax');
            try
                l = evalin('base', lower_limit);
                u = evalin('base', upper_limit);
                %calling all twise in the case of l or u are N-D arrays
                UpperIsInf = all(all(isinf(u)));
                LowerIsInf = all(all(isinf(l)));
            catch
                UpperIsInf= false;
                LowerIsInf = false;
            end
            if UpperIsInf && LowerIsInf
                NASAPPUtils.replace_one_block(saturation_list{i},'pp_lib/saturation_upper_and_lower_is_Inf');
            elseif UpperIsInf
                NASAPPUtils.replace_one_block(saturation_list{i},'pp_lib/saturation_upper_is_Inf');
            elseif LowerIsInf
                NASAPPUtils.replace_one_block(saturation_list{i},'pp_lib/saturation_lower_is_Inf');
            else
                NASAPPUtils.replace_one_block(saturation_list{i},'pp_lib/saturation');
            end
            if ~LowerIsInf
                set_param(strcat(saturation_list{i},'/lower_limit'),...
                    'Value',lower_limit);
            end
            if ~UpperIsInf
                set_param(strcat(saturation_list{i},'/upper_limit'),...
                    'Value',upper_limit);
            end
            if strcmp(outputDataType, 'Inherit: Same as input')
                %Inherit: Inherit via back propagation
                if ~UpperIsInf
                    set_param(strcat(saturation_list{i},'/upper'),...
                        'OutDataTypeStr','Inherit: Inherit via back propagation');
                    set_param(strcat(saturation_list{i},'/upper_limit'),...
                        'OutDataTypeStr','Inherit: Inherit via back propagation');
                end
                if ~LowerIsInf
                    set_param(strcat(saturation_list{i},'/lower'),...
                        'OutDataTypeStr','Inherit: Inherit via back propagation');
                    set_param(strcat(saturation_list{i},'/lower_limit'),...
                        'OutDataTypeStr','Inherit: Inherit via back propagation');
                end
            else
                if ~UpperIsInf
                    set_param(strcat(saturation_list{i},'/upper'),...
                        'OutDataTypeStr',outputDataType);
                    set_param(strcat(saturation_list{i},'/upper_limit'),...
                        'OutDataTypeStr',outputDataType);
                end
                if ~LowerIsInf
                    set_param(strcat(saturation_list{i},'/lower'),...
                        'OutDataTypeStr',outputDataType);
                    set_param(strcat(saturation_list{i},'/lower_limit'),...
                        'OutDataTypeStr',outputDataType);
                end
            end
            set_param(strcat(saturation_list{i},'/Out'), 'OutMin', OutMin);
            set_param(strcat(saturation_list{i},'/Out'), 'OutMax', OutMax);
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('saturation pre-process has failed for block %s', saturation_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', Constants.INFO, 'Saturation_pp', '');
end
end
