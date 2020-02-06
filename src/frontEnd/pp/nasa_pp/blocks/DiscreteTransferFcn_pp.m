%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>, Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function [status, errors_msg] = DiscreteTransferFcn_pp(model)
    % DiscreteTransferFcn_pp searches for DiscreteTransferFcn_pp blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    % Processing DiscreteTransferFcn blocks
    status = 0;
    errors_msg = {};
    
    dtf_list = find_system(model,...
        'LookUnderMasks', 'all', 'BlockType','DiscreteTransferFcn');
    dtf_list = [dtf_list; find_system(model,'BlockType','TransferFcn')];
    
    if not(isempty(dtf_list))
        display_msg('Replacing DiscreteTransferFcn blocks...', MsgType.INFO,...
            'DiscreteTransferFcn_pp', '');
        
        
        U_dims = SLXUtils.tf_get_U_dims(model, 'DiscreteTransferFcn_pp', dtf_list);
        
        %% pre-processing blocks
        for i=1:length(dtf_list)
            try
                if isempty(U_dims{i})
                    continue;
                end
                display_msg(dtf_list{i}, MsgType.INFO, ...
                    'DiscreteTransferFcn_pp', '');
                
                % Obtaining z-expression parameters
                % get denominator
                denum_str = get_param(dtf_list{i}, 'Denominator');
                [denum, ~, status] = SLXUtils.evalParam(...
                    model, ...
                    get_param(dtf_list{i}, 'Parent'), ...
                    dtf_list{i}, ...
                    denum_str);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        denum_str, dtf_list{i}), ...
                        MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                    continue;
                end
                
                % get numerator
                num_str = get_param(dtf_list{i},'Numerator');
                [num, ~, status] = SLXUtils.evalParam(...
                    model, ...
                    get_param(dtf_list{i}, 'Parent'), ...
                    dtf_list{i}, ...
                    num_str);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        num_str, dtf_list{i}), ...
                        MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                    continue;
                end
                
                blocktype= get_param(dtf_list{i}, 'BlockType');
                if strcmp(blocktype, 'TransferFcn')
                    try
                        Hc = tf(num, denum);
                        sampleT = SLXUtils.getModelCompiledSampleTime(model);
                        Hd = c2d(Hc,sampleT);
                        num = Hd.Numerator{:};
                        denum = Hd.Denominator{:};
                    catch me
                        display_msg(sprintf('block %s is not supported. Please change it to DiscreteTransferFcn',...
                            dtf_list{i}), ...
                            MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                        display_msg(me.getReport(), ...
                            MsgType.DEBUG, 'DiscreteTransferFcn_pp', '');
                        continue
                    end
                end
                
                NASAPPUtils.replace_DTF_block(dtf_list{i}, U_dims{i},num,denum, 'DiscreteTransferFcn');
                set_param(dtf_list{i}, 'LinkStatus', 'inactive');
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('DiscreteTransferFcn pre-process has failed for block %s', dtf_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'DiscreteTransferFcn_pp', '');
    end
end




