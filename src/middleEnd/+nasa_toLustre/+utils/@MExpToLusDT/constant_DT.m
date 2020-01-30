function [lusDT, slxDT] = constant_DT(tree, varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if strcmp(tree.dataType, 'Integer') || strcmp(tree.dataType, 'Float')
        %e.g., for matlab "1" is double
        lusDT = 'real';
        slxDT = 'double';
    else
        lusDT = '';
        slxDT = '';
    end
end