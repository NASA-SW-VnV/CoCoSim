function body = addInlineIndexFromArrayIndicesCode(...
        inline_list,element,index)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function takes a cell array of VarIdExpr, an VarIdExpr for the
    % index and return an VarIdExpr for the array element of that index

    conds = cell(1,numel(inline_list)-1);
    thens = cell(1,numel(inline_list));
    for j=1:numel(inline_list)-1
        conds{j} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.EQ,index,...
            nasa_toLustre.lustreAst.IntExpr(j));
        thens{j} = inline_list{j};
    end
    thens{numel(inline_list)} = inline_list{numel(inline_list)};
    if numel(inline_list) == 1
        rhs = nasa_toLustre.lustreAst.IteExpr(conds{1},thens{1},thens{2});
    else
        rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
    end
    body{1} = ...
        nasa_toLustre.lustreAst.LustreEq(element,rhs);
end

