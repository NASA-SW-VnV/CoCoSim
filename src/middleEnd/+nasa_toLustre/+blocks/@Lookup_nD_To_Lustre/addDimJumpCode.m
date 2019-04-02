function [body, vars,Ast_dimJump] = addDimJumpCode(blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %  This function defines dimJump.  table breakpoints and values are inline in Lustre, the
    %  interpolation formulation uses index for each dimension.  We
    %  need to get the inline data from the dimension subscript.
    %  Function addDimJumpCode calculate the index jump in the inline when we
    %  change dimension subscript.  For example dimJump(2) = 3 means
    %  to increase subscript dimension 2 by 1, we have to jump 3
    %  spaces in the inline storage.
    
    indexDataType = 'int';
    NumberOfTableDimensions = blkParams.NumberOfAdjustedTableDimensions;
    body = cell(1,NumberOfTableDimensions);
    vars = cell(1,NumberOfTableDimensions);            
    dimJump = ones(1,NumberOfTableDimensions);
    L_dimjump = cell(1,NumberOfTableDimensions);
    L_dimjump{1} =  nasa_toLustre.lustreAst.VarIdExpr(...
        sprintf('dimJump_%d',1));
    Ast_dimJump = cell(1,NumberOfTableDimensions);
    Ast_dimJump{1} = nasa_toLustre.lustreAst.IntExpr(1);
    vars{1} = nasa_toLustre.lustreAst.LustreVar(...
        L_dimjump{1},indexDataType);
    body{1} = nasa_toLustre.lustreAst.LustreEq(...
        L_dimjump{1},nasa_toLustre.lustreAst.IntExpr(dimJump(1)));
    for i=2:NumberOfTableDimensions
        L_dimjump{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('dimJump_%d',i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            L_dimjump{i},indexDataType);
        for j=1:i-1
            if LookupType.isInterpolation_nD(blkParams.lookupTableType)
                tableSize = size(blkParams.Table);                
                dataPointInDim = tableSize(j);
            else    
                dataPointInDim = numel(blkParams.BreakpointsForDimension{j});
            end
            dimJump(i) = dimJump(i)*dataPointInDim;
        end
        body{i} = nasa_toLustre.lustreAst.LustreEq(...
            L_dimjump{i},nasa_toLustre.lustreAst.IntExpr(dimJump(i)));
        Ast_dimJump{i} = nasa_toLustre.lustreAst.IntExpr(dimJump(i));
    end
end

