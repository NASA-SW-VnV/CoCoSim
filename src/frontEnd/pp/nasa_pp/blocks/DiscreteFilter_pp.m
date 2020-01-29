%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
%function [status, errors_msg] = DiscreteFilter_pp(model)
    % DiscreteFilter_pp searches for DiscreteFilter_pp blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    % Processing Gain blocks
    status = 0;
    errors_msg = {};
    
    dFilter_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','DiscreteFilter');
    if not(isempty(dFilter_list))
        display_msg('Replacing DiscreteFilter blocks...', MsgType.INFO,...
            'DiscreteFilter_pp', '');
        U_dims = SLXUtils.tf_get_U_dims(model, 'DiscreteFilter_pp', dFilter_list);
        
        %% pre-processing blocks
        for i=1:length(dFilter_list)
            try
                if isempty(U_dims{i})
                    continue;
                end
                display_msg(dFilter_list{i}, MsgType.INFO, ...
                    'DiscreteFilter_pp', '');
                
                
                Filter_structure = get_param(dFilter_list{i}, 'FilterStructure');
                if strcmp(Filter_structure, 'Direct form I') ...
                        || strcmp(Filter_structure, 'Direct form I transposed') ...
                        || strcmp(Filter_structure, 'Direct form II transposed')
                    display_msg(sprintf('Filter_structure %s in block %s is not supported',...
                        Filter_structure, blk), ...
                        MsgType.ERROR, 'DiscreteFilter_pp', '');
                    continue;
                end
                
                % Obtaining z-expression parameters
                denum_str = get_param(dFilter_list{i}, 'Denominator');
                [denum, ~, status] = SLXUtils.evalParam(...
                    model, ...
                    get_param(dFilter_list{i}, 'Parent'), ...
                    dFilter_list{i}, ...
                    denum_str);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        denum_str, dFilter_list{i}), ...
                        MsgType.ERROR, 'DiscreteFilter_pp', '');
                    continue;
                end
                
                % get numerator
                num_str = get_param(dFilter_list{i},'Numerator');
                [num, ~, status] = SLXUtils.evalParam(...
                    model, ...
                    get_param(dFilter_list{i}, 'Parent'), ...
                    dFilter_list{i}, ...
                    num_str);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        num_str, dFilter_list{i}), ...
                        MsgType.ERROR, 'DiscreteFilter_pp', '');
                    continue;
                end
                
                NASAPPUtils.replace_DTF_block(dFilter_list{i}, U_dims{i},num,denum, 'DiscreteFilter');
                set_param(dFilter_list{i}, 'LinkStatus', 'inactive');
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('DiscreteFilter pre-process has failed for block %s', dFilter_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'DiscreteFilter_pp', '');
    end
end


