function [] = DiscreteFIRFilter_pp(model)
% DiscreteFIRFilter_pp searches for DiscreteFIRFilter_pp blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>, Trinh, Khanh V <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Gain blocks
dFir_list = find_system(model,'LookUnderMasks', 'all', 'BlockType','DiscreteFir');
if not(isempty(dFir_list))
    display_msg('Replacing DiscreteFIRFilter blocks...', MsgType.INFO,...
        'DiscreteFIRFilter_pp_pp', '');
    
    U_dims = SLXUtils.tf_get_U_dims(model, 'DiscreteTransferFcn_pp', dFir_list);
    
    %% pre-processing blocks
    for i=1:length(dFir_list)
        if isempty(U_dims{i}) 
            continue;
        end
        display_msg(dFir_list{i}, MsgType.INFO, ...
            'DiscreteFIRFilter_pp', '');
        
        Filter_structure = get_param(dFir_list{i}, 'FilterStructure');
        if strcmp(Filter_structure, 'Direct form symmetric')
            display_msg(sprintf('Filter_structure %s in block %s is not supported',...
                Filter_structure, blk), ...
                MsgType.ERROR, 'DiscreteFIRFilter_pp', '');
            continue;
        end
        
        Filter_structure = get_param(dFir_list{i}, 'FilterStructure');
        if strcmp(Filter_structure, 'Direct form antisymmetric')
            display_msg(sprintf('Filter_structure %s in block %s is not supported',...
                Filter_structure, blk), ...
                MsgType.ERROR, 'DiscreteFIRFilter_pp', '');
            continue;
        end   
        
        Filter_structure = get_param(dFir_list{i}, 'FilterStructure');
        if strcmp(Filter_structure, 'Direct form transposed')
            display_msg(sprintf('Filter_structure %s in block %s is not supported',...
                Filter_structure, blk), ...
                MsgType.ERROR, 'DiscreteFIRFilter_pp', '');
            continue;
        end
        
        Filter_structure = get_param(dFir_list{i}, 'FilterStructure');
        if strcmp(Filter_structure, 'Lattice MA')
            display_msg(sprintf('Filter_structure %s in block %s is not supported',...
                Filter_structure, blk), ...
                MsgType.ERROR, 'DiscreteFIRFilter_pp', '');
            continue;
        end         

        % Obtaining z-expression parameters
        % get numerator
        [num, status] = PPUtils.getTfNumerator(model,dFir_list{i}, 'Coefficients','DiscreteFIRFilter_pp');
        if status
            continue;
        end

        % Computing state space representation
        denum = zeros(1,length(num));
        denum(1) = 1;
       
        PPUtils.replace_DTF_block(dFir_list{i}, U_dims{i},num,denum);
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteFIRFilter_pp', '');
end
end


