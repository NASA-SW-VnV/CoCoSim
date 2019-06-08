function [status, errors_msg] = DiscreteTransferFcn_pp(model)
    % DiscreteTransferFcn_pp searches for DiscreteTransferFcn_pp blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>, Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                    catch
                        display_msg(sprintf('block %s is not supported. Please change it to DiscreteTransferFcn',...
                            dtf_list{i}), ...
                            MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                        continue
                    end
                end
                
                PP2Utils.replace_DTF_block(dtf_list{i}, U_dims{i},num,denum, 'DiscreteTransferFcn');
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




