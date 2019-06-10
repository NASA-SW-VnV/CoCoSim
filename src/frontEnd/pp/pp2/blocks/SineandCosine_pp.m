function [status, errors_msg] = SineandCosine_pp(model)
% SineandCosine_pp Searches for Sine and Cosine blocks and inline thier
% contents to avoid algebraic loops.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing SineandCosine blocks
status = 0;
errors_msg = {};

SineandCosine_list = find_system(model, ...
    'LookUnderMasks', 'all', 'MaskType','Sine and Cosine');
if not(isempty(SineandCosine_list))
    display_msg('Replacing SineandCosine blocks...', MsgType.INFO,...
        'SineandCosine_pp', '');
    for i=1:length(SineandCosine_list)
        try
            display_msg(SineandCosine_list{i}, MsgType.INFO, ...
                'SineandCosine_pp', '');
            quarter_blocks = find_system(SineandCosine_list{i}, ...
                'FollowLinks', 'on', 'LookUnderMasks', 'all',...
                'MaskType', 'Fixed-Point-Private Quandrant Processing Sine');
            if isempty(quarter_blocks)
                continue;
            end
            quarter_block = quarter_blocks{1};
            % disable link for Sine and Cosine
            [status, errors_msg_i] = LinkStatus_pp( SineandCosine_list{i} );
            errors_msg = MatlabUtils.concat(errors_msg, errors_msg_i);
            if status
                continue;
            end
            % remove mask and atomic
            p = Simulink.Mask.get(quarter_block);
            if ~isempty(p), p.delete; end
            set_param(quarter_block,'TreatAsAtomicUnit', 'off');
            Simulink.BlockDiagram.expandSubsystem(quarter_block);
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'SineandCosine_pp', '');
            status = 1;
            errors_msg{end + 1} = sprintf('SineandCosine pre-process has failed for block %s', SineandCosine_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'SineandCosine_pp', '');
end

end

