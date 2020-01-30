function [lusDT, slxDT] = constant_DT(tree, varargin)

    
    if strcmp(tree.dataType, 'Integer') || strcmp(tree.dataType, 'Float')
        %e.g., for matlab "1" is double
        lusDT = 'real';
        slxDT = 'double';
    else
        lusDT = '';
        slxDT = '';
    end
end