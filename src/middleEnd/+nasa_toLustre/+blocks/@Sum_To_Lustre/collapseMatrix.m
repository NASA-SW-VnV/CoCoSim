function [numelCollapseDim, delta, collapseDims] = collapseMatrix(in_matrix_dimension, CollapseDim)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    numelCollapseDim = in_matrix_dimension{1}.dims(CollapseDim);
    matSize = in_matrix_dimension{1}.dims;

    subscripts = ones(1,in_matrix_dimension{1}.numDs);
    subscripts(CollapseDim) = 2;
    sub2ind_string = 'ind1 = sub2ind(matSize';
    for j=1:in_matrix_dimension{1}.numDs
        sub2ind_string = sprintf('%s, 1',sub2ind_string);
    end
    sub2ind_string = sprintf('%s);',sub2ind_string);
    eval(sub2ind_string);
    sub2ind_string = 'ind2 = sub2ind(matSize';
    for j=1:in_matrix_dimension{1}.numDs
        sub2ind_string = sprintf('%s, %d',sub2ind_string,subscripts(j));
    end
    sub2ind_string = sprintf('%s);',sub2ind_string);
    eval(sub2ind_string);
    delta = ind2-ind1;
    collapseDims = matSize;
    collapseDims(CollapseDim) = 1;
end


