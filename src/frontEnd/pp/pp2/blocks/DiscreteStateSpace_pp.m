function [] = DiscreteStateSpace_pp(model)
% DiscreteStateSpace_pp Searches for DiscreteStateSpace blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Gain blocks
dss_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','DiscreteStateSpace');
dss_list = [dss_list; find_system(model,'BlockType','StateSpace')];
if not(isempty(dss_list))
    display_msg('Replacing DiscreteStateSpace blocks...', MsgType.INFO,...
        'DiscreteStateSpace_pp', '');
    for i=1:length(dss_list)
        display_msg(dss_list{i}, MsgType.INFO, ...
            'DiscreteStateSpace_pp', '');
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
                [a, status] = SLXUtils.evalParam(model, A);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        A, dss_list{i}), ...
                        MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                    continue;
                end
                [b, status] = SLXUtilsgit .evalParam(model, B);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        A, dss_list{i}), ...
                        MsgType.ERROR, 'DiscreteTransferFcn_pp', '');
                    continue;
                end
                [Phi, Gamma] = PPUtils.c2d(a, b ,ST);
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
        replace_one_block(dss_list{i},'pp_lib/DSS');
        
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
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteStateSpace_pp', '');
end
end

