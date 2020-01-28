%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the
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
function [status, errors_msg] = DiscreteStateSpace_pp(model)
    % DiscreteStateSpace_pp Searches for DiscreteStateSpace blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    % Processing Gain blocks
    status = 0;
    errors_msg = {};
    
    dss_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','DiscreteStateSpace');
    dss_list = [dss_list; find_system(model,'BlockType','StateSpace')];
    
    if not(isempty(dss_list))
        compiledInportDim = SLXUtils.getCompiledParam(dss_list, 'CompiledPortDimensions');
        inportDimMap = containers.Map(dss_list, compiledInportDim);
        display_msg('Replacing DiscreteStateSpace blocks...', MsgType.INFO,...
            'DiscreteStateSpace_pp', '');
        for i=1:length(dss_list)
            display_msg(dss_list{i}, MsgType.INFO, ...
                'DiscreteStateSpace_pp', '');
            try
                % Get infos from the original block
                A = get_param(dss_list{i},'A');
                B = get_param(dss_list{i},'B');
                C = get_param(dss_list{i},'C');
                D = get_param(dss_list{i},'D');
                try
                    Init = get_param(dss_list{i},'InitialCondition');
                catch
                    Init = get_param(dss_list{i},'X0');
                end
                
                blocktype= get_param(dss_list{i}, 'BlockType');
                if strcmp(blocktype, 'StateSpace')
                    try
                        ST = SLXUtils.getModelCompiledSampleTime(model);
                        [a, ~, status] = SLXUtils.evalParam(...
                            model, ...
                            get_param(dss_list{i},'Parent'), ...
                            dss_list{i}, ...
                            A);
                        if status
                            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                A, dss_list{i}), ...
                                MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                            continue;
                        end
                        [b, ~, status] = SLXUtils.evalParam(...
                            model, ...
                            get_param(dss_list{i},'Parent'), ...
                            dss_list{i}, ...
                            B);
                        if status
                            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                                A, dss_list{i}), ...
                                MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                            continue;
                        end
                        [Phi, Gamma] = NASAPPUtils.c2d(a, b ,ST);
                        A = mat2str(Phi);
                        B = mat2str(Gamma);
                    catch
                        display_msg(sprintf('block %s is not supported. Please change it to DiscreteTransferFcn',...
                            dss_list{i}), ...
                            MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                        continue
                    end
                    ST = num2str(ST);
                else
                    ST = get_param(dss_list{i},'SampleTime');
                end
                % replacing
                NASAPPUtils.replace_one_block(dss_list{i},'pp_lib/DSS');
                % restoring info
                set_param(strcat(dss_list{i},'/A'),...
                    'Value',A);
                set_param(strcat(dss_list{i},'/B'),...
                    'Value',B);
                set_param(strcat(dss_list{i},'/C'),...
                    'Value',C);
                set_param(strcat(dss_list{i},'/D'),...
                    'Value',D);
                try
                    set_param(strcat(dss_list{i},'/X0'),...
                        'InitialCondition',Init);
                catch
                    set_param(strcat(dss_list{i},'/X0'),...
                        'X0',Init);
                end
                set_param(strcat(dss_list{i},'/X0'),...
                    'SampleTime',ST);
                set_param(strcat(dss_list{i},'/U'),...
                    'SampleTime',ST);
                try
                    if inportDimMap.isKey(dss_list{i})
                        U_dim = inportDimMap(dss_list{i}).Inport;
                        U_dim = U_dim(2:end);
                        set_param(strcat(dss_list{i},'/U'),...
                            'PortDimensions',mat2str(U_dim));
                    end
                catch
                    % ignore
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('DiscreteStateSpace pre-process has failed for block %s', dss_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'DiscreteStateSpace_pp', '');
    end
end

