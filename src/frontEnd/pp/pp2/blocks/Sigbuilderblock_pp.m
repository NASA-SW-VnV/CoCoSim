function [status, errors_msg] = Sigbuilderblock_pp(model)
    % Sigbuilderblock_pp searches for Sigbuilderblock_pp blocks and
    % replaces them by Inports
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Processing Sigbuilderblock blocks
    status = 0;
    errors_msg = {};

    sigBuilder_list = find_system(model,...
        'LookUnderMasks', 'all', 'MaskType','Sigbuilder block');

    if not(isempty(sigBuilder_list))
        display_msg('Replacing Signal Builder blocks...', MsgType.INFO,...
            'Sigbuilderblock_pp', '');

        %% pre-processing blocks
        for i=1:length(sigBuilder_list)
            display_msg(sigBuilder_list{i}, MsgType.INFO, ...
                'Sigbuilderblock_pp', '');
            try
                name = get_param(sigBuilder_list{i},'Name');
                Orient=get_param(sigBuilder_list{i},'orientation');

                ssBuilder = get_param(sigBuilder_list{i}, 'PortHandles');
                %save  infos before removing block
                position = {};
                distinations = {};
                for j=1:numel(ssBuilder.Outport)
                    position{j} = get_param(ssBuilder.Outport(j),'position');

                    sourceLine = get_param(ssBuilder.Outport(j), 'line');
                    if sourceLine == -1
                        % no connected line
                        distinations{j} = [];
                        continue;
                    end
                    distinations{j} = get_param(sourceLine, 'DstPortHandle');
                end
                % remove block
                delete_block(sigBuilder_list{i});

                for j=1:numel(ssBuilder.Outport)
                    pos=position{j};
                    new_pos = [(pos(1) -40) (pos(2)-17) (pos(1) - 10), (pos(2)-3)];
                    inport_path = sprintf('%s_%d', sigBuilder_list{i}, j);
                    inport_handle = add_block('simulink/Commonly Used Blocks/In1',inport_path, ...
                        'MakeNameUnique', 'on', ...
                        'Orientation',Orient, ...
                        'Position',new_pos);
                    srcPortHandle = get_param(inport_handle,'PortHandles');
                    for d=distinations{j}'
                        if isempty(d)
                            continue;
                        end
                        l = get_param(d, 'line');
                        try delete(l); catch, end
                        add_line(get_param(inport_handle, 'Parent'), srcPortHandle.Outport(1), d, 'autorouting', 'on');
                    end
                    % check to see if there is parent block, if yes add another IN1 in
                    % parent block
                    cur_parent = get_param(inport_handle, 'parent');
                    while ~isempty(cur_parent) && ~isempty(get_param(cur_parent,'parent'))
                        DstBlkH = get_param(cur_parent, 'PortHandles');
                        inport_pos = get_param(DstBlkH.Inport(end), 'Position');
                        inport_pos = [(inport_pos(1)-40), (inport_pos(2)-17), (inport_pos(1) - 10), (inport_pos(2)-3)];
                        grand_parent = get_param(cur_parent,'parent');
                        inport_path = fullfile(grand_parent, name);
                        inpot_handle= add_block('simulink/Commonly Used Blocks/In1',inport_path,...
                            'MakeNameUnique', 'on', ...
                            'Position',inport_pos);
                        SrcBlkH = get_param(inpot_handle,'PortHandles');
                        add_line(grand_parent, SrcBlkH.Outport(1), DstBlkH.Inport(end), 'autorouting', 'on');
                        cur_parent = grand_parent;
                    end
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('Sigbuilderblock pre-process has failed for block %s', sigBuilder_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'Sigbuilderblock_pp', '');
    end
end




