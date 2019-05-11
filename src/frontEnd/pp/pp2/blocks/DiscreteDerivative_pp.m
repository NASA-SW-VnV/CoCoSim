function [status, errors_msg] = DiscreteDerivative_pp(model)
    % DiscreteDerivative_pp searches for DiscreteDerivative_pp blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Processing DiscreteDerivative blocks
    status = 0;
    errors_msg = {};

    dDerivative_list = find_system(model,...
        'LookUnderMasks', 'all', 'MaskType','Discrete Derivative');
    if not(isempty(dDerivative_list))
        display_msg('Replacing DiscreteDerivative blocks...', MsgType.INFO,...
            'DiscreteDerivative_pp', '');

        %% pre-processing blocks
        for i=1:length(dDerivative_list)
            try
                display_msg(dDerivative_list{i}, MsgType.INFO, ...
                    'DiscreteDerivative_pp', '');

                OutDataTypeStr = get_param(dDerivative_list{i}, 'OutDataTypeStr');
                RndMeth =  get_param(dDerivative_list{i}, 'RndMeth');
                DoSatur = get_param(dDerivative_list{i}, 'DoSatur');
                gainval = get_param(dDerivative_list{i}, 'gainval');
                [gainval, ~, status] = ...
                    SLXUtils.evalParam(...
                    model, ...
                    get_param(dDerivative_list{i}, 'Parent'), ...
                    dDerivative_list{i}, ...
                    gainval);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        gainval, dDerivative_list{i}), ...
                        MsgType.ERROR, 'DiscreteDerivative_pp', '');
                    continue;
                end

                ICPrevScaledInput = get_param(dDerivative_list{i}, 'ICPrevScaledInput');
                OutMin = get_param(dDerivative_list{i}, 'OutMin');
                OutMax = get_param(dDerivative_list{i}, 'OutMax');

                % replacing
                PP2Utils.replace_one_block(dDerivative_list{i},'pp_lib/DiscreteDerivative');

                blkName = dDerivative_list{i};

                if (gainval == 0.0)
                    %avoid divide by zero warning
                    inverseGainval = inf;
                else
                    inverseGainval = 1.0/double(gainval);
                end
                set_param([blkName,'/TSamp'], ...
                    'weightValue',num2str(inverseGainval));

                if strcmp(OutDataTypeStr, 'Inherit: Inherit via internal rule')
                    diffDT   = 'Inherit: Inherit via back propagation';
                    tsampDT  = 'Inherit: Inherit via internal rule';
                    tsampImp = 'Offline Scaling Adjustment';
                else
                    diffDT   = OutDataTypeStr;
                    tsampDT  = 'Inherit: Inherit via back propagation';
                    tsampImp = 'Online Calculations';
                end
                set_param([blkName,'/Diff'], ...
                    'OutDataTypeStr',diffDT);
                set_param([blkName,'/Diff'], ...
                    'RndMeth',RndMeth, ...
                    'DoSatur',DoSatur);
                set_param([blkName,'/TSamp'], ...
                    'OutDataTypeStr',tsampDT, ...
                    'RndMeth',RndMeth, ...
                    'DoSatur',DoSatur, ...
                    'TsampMathImp',tsampImp);

                set_param([blkName,'/UD'], ...
                    'InitialCondition',ICPrevScaledInput);

                
                set_param(strcat(dDerivative_list{i},'/Y'), 'OutMin', OutMin);
                set_param(strcat(dDerivative_list{i},'/Y'), 'OutMax', OutMax);
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('DiscreteDerivative pre-process has failed for block %s', dDerivative_list{i});
                continue;            
            end

        end
        display_msg('Done\n\n', MsgType.INFO, 'DiscreteDerivative_pp', '');
    end
end


