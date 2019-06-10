function [body, vars] = addInlineIndexFromArrayIndicesCode(...
        inline_list,element,index)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function takes a cell array of VarIdExpr, an VarIdExpr for the
    % index and return an VarIdExpr for the array element of that index

    %     % First SOLUTION, Direct search O(n)
    %     vars = {};
    %     nb_elt =  numel(inline_list);
    %     conds = cell(1,numel(inline_list)-1);
    %     thens = cell(1,numel(inline_list));
    %     for j=1:numel(inline_list)-1
    %         conds{j} = nasa_toLustre.lustreAst.BinaryExpr(...
    %             nasa_toLustre.lustreAst.BinaryExpr.EQ,index,...
    %             nasa_toLustre.lustreAst.IntExpr(j));
    %         thens{j} = inline_list{j};
    %     end
    %     thens{nb_elt} = inline_list{nb_elt};
    %     if nb_elt == 1
    %         rhs = inline_list{1};
    %     else
    %         rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
    %     end
    %     body{1} = ...
    %         nasa_toLustre.lustreAst.LustreEq(element,rhs);
    
    
    % Second solution: Binary search O(log(n)). Reduce number of If-else
    % branches for GCC.
    [body, vars] = nasa_toLustre.lustreAst.IteExpr.binarySearch(...
                inline_list, index, element.getId(),...
                'real', [], [], [], element.getId());
    
end

