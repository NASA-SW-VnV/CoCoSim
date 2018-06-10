function [] = DiscreteTransferFcn_pp(model)
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
dtf_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','DiscreteTransferFcn');
dtf_list = [dtf_list; find_system(model,'BlockType','TransferFcn')];

if not(isempty(dtf_list))
    display_msg('Replacing DiscreteTransferFcn blocks...', MsgType.INFO,...
        'DiscreteTransferFcn_pp', '');
    
    U_dims = SLXUtils.tf_get_U_dims(model, 'DiscreteTransferFcn_pp', dtf_list);
    
    %% pre-processing blocks
    for i=1:length(dtf_list)
        if isempty(U_dims{i}) 
            continue;
        end
        display_msg(dtf_list{i}, MsgType.INFO, ...
            'DiscreteTransferFcn_pp', '');
 
        % Obtaining z-expression parameters 
        % get denominator
        [denum, status] = PPUtils.getTfDenum(model,dtf_list{i}, 'DiscreteTransferFcn_pp');
        if status
            continue;
        end        
        % get numerator
        [num, status] = PPUtils.getTfNumerator(model,dtf_list{i}, 'Numerator','DiscreteTransferFcn_pp');
        if status
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
        
        PPUtils.replace_DTF_block(dtf_list{i}, U_dims{i},num,denum);
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteTransferFcn_pp', '');
end
end




