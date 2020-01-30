function [lusDT, slxDT] = transpose_DT(tree, args)

%    
    
    [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.leftExp, args);
end

