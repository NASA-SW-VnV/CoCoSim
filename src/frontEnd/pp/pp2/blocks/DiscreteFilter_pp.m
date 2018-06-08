function [] = DiscreteFilter_pp(model)
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
dFilter_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','DiscreteFilter');
if not(isempty(dFilter_list))
    display_msg('Replacing DiscreteFilter blocks...', MsgType.INFO,...
        'DiscreteFilter_pp', '');
    U_dims = SLXUtils.tf_get_U_dims(model, 'DiscreteFilter_pp', dFilter_list);
    
    %% pre-processing blocks
    for i=1:length(dFilter_list)
        if isempty(U_dims{i}) 
            continue;
        end
        display_msg(dFilter_list{i}, MsgType.INFO, ...
            'DiscreteFilter_pp', '');
        
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
        
        % Computing state space representation
        [A,B,C,D]=tf2ss(num,denum);
        
        A = mat2str(A);
        B = mat2str(B);
        C = mat2str(C);
        D = mat2str(D);
        
        PPUtils.replace_DTF_block(dFilter_list{i}, A, B, C, D, U_dims{i} );
        
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteFilter_pp', '');
end
end


