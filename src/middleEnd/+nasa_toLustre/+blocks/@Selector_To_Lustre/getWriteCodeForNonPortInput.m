function [codes] = getWriteCodeForNonPortInput(~, numOutDims,...
        inputs,outputs,ind,outputDimsArray,...
        in_matrix_dimension) % do not remove in_matrix_dimension parameter
                            % It is used in eveal function.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % initialization
    
    codes = {};
%     if numOutDims > 7
%         display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
%             indexBlock.Origin_path), ...
%             MsgType.ERROR, 'Selector_To_Lustre', '');
%         return;
%     elseif numOutDims == 1
%         codes = cell(1, numel(outputs));
%         for i=1:numel(outputs)
%             U_index = ind{1}(i);
%             codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{1}{U_index});
%         end
%     else
%         % support max dimensions = 7
%         codes = cell(1, numel(outputs));
%         for i=1:numel(outputs)
%             [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(outputDimsArray,i);
%             d = [d1, d2, d3, d4, d5, d6, d7 ];
% 
%             sub2ind_string = 'U_index = sub2ind(in_matrix_dimension{1}.dims';
%             dString = {'[ ', '[ ', '[ ', '[ ', '[ ', '[ ', '[ '};
%             for j=1:numOutDims
%                 Ud(j) = ind{j}(d(j));
%                 if i==1
%                     dString{j}  = sprintf('%s%d', dString{j}, Ud(j));
%                 else
%                     dString{j}  = sprintf('%s, %d', dString{j}, Ud(j));
%                 end
%             end
% 
%             for j=1:numOutDims
%                 sub2ind_string = sprintf('%s, %s]',sub2ind_string,dString{j});
%             end
% 
%             sub2ind_string = sprintf('%s);',sub2ind_string);
%             eval(sub2ind_string);
%             codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{1}{U_index});
%         end
% 
%     end
    in_matrix_dimension_1_dims = in_matrix_dimension{1}.dims;
    if numel(in_matrix_dimension_1_dims) == 1
        in_matrix_dimension_1_dims = [1, in_matrix_dimension_1_dims];
    end
    U_reshaped = reshape(inputs{1}, in_matrix_dimension_1_dims);
    Y = U_reshaped(ind{:});
    Y_inlined = reshape(Y, [1, numel(Y)]);
    for i=1:numel(outputs)
        codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, Y_inlined{i});
    end
end
