%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function [status, errors_msg] = Sigbuilderblock_pp(model)
    % Sigbuilderblock_pp searches for Sigbuilderblock_pp blocks and
    % replaces them by Inports
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




