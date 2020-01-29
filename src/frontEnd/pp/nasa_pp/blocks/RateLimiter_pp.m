%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function [status, errors_msg] = RateLimiter_pp(model)
    % RateLimiter_pp searches for RateLimiter_pp blocks and replaces them by a
    % Processing RateLimiter blocks
    status = 0;
    errors_msg = {};

    rateLimiter_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','RateLimiter');

    if not(isempty(rateLimiter_list))
        display_msg('Replacing Rate Limiter blocks...', MsgType.INFO,...
            'RateLimiter_pp', '');

        %% pre-processing blocks
        for i=1:length(rateLimiter_list)
            display_msg(rateLimiter_list{i}, MsgType.INFO, ...
                'RateLimiter_pp', '');
            try

                RisingSlewLimit = get_param(rateLimiter_list{i},'RisingSlewLimit' );
                FallingSlewLimit = get_param(rateLimiter_list{i},'FallingSlewLimit' );
                Init = get_param(rateLimiter_list{i},'InitialCondition');
                % replace it
                NASAPPUtils.replace_one_block(rateLimiter_list{i},'pp_lib/RateLimiter');
                %restore information
                set_param(strcat(...
                    rateLimiter_list{i} ,'/R'),...
                    'Value', ...
                    RisingSlewLimit);
                set_param(strcat(...
                    rateLimiter_list{i} ,'/F'), ...
                    'Value', ...
                    FallingSlewLimit);
                ST = SLXUtils.getModelCompiledSampleTime(model);
                set_param(...
                    strcat(rateLimiter_list{i} ,'/TS'),...
                    'Value', ...
                    num2str(ST));
                try
                    set_param(strcat(rateLimiter_list{i},'/UD'),...
                        'InitialCondition',Init);
                catch
                    % the parameter is called X0 in previous verfsions of Simulink
                    set_param(strcat(rateLimiter_list{i},'/UD'),...
                        'X0',Init);
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('rateLimiter pre-process has failed for block %s', rateLimiter_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'RateLimiter_pp', '');
    end
end




