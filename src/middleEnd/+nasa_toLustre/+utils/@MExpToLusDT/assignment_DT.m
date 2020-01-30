function [lusDT, slxDT] = assignment_DT(tree, args)

    
    args.isLeft = true;
    [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
        tree.leftExp, args);
end

