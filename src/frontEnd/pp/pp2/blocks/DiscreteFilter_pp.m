function [status, errors_msg] = DiscreteFilter_pp(model)
    % DiscreteFilter_pp searches for DiscreteFilter_pp blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                [denum, status] = PPUtils.getTfDenum(model,dFilter_list{i}, 'DiscreteFilter_pp');
                if status
                    continue;
                end
                % get numerator
                [num, status] = PPUtils.getTfNumerator(model,dFilter_list{i},'Numerator', 'DiscreteFilter_pp');
                if status
                    continue;
                end

                PPUtils.replace_DTF_block(dFilter_list{i}, U_dims{i},num,denum);
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


