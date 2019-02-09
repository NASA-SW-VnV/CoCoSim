
function [body, vars,Ast_dimJump] = ...
        addDimJumpCode(NumberOfTableDimensions,blk_name,...
        indexDataType,BreakpointsForDimension)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    %  This function defines dimJump.  table breakpoints and values are inline in Lustre, the
    %  interpolation formulation uses index for each dimension.  We
    %  need to get the inline data from the dimension subscript.
    %  Function addDimJumpCode calculate the index jump in the inline when we
    %  change dimension subscript.  For example dimJump(2) = 3 means
    %  to increase subscript dimension 2 by 1, we have to jump 3
    %  spaces in the inline storage.
    body = cell(1,NumberOfTableDimensions);
    vars = cell(1,NumberOfTableDimensions);            
    dimJump = ones(1,NumberOfTableDimensions);
    L_dimjump = cell(1,NumberOfTableDimensions);
    L_dimjump{1} =  VarIdExpr(sprintf('%s_dimJump_%d',blk_name,1));
    Ast_dimJump = cell(1,NumberOfTableDimensions);
    Ast_dimJump{1} = IntExpr(1);
    %vars = sprintf('%s\t%s:%s;\n',vars,L_dimjump{1},indexDataType);
    vars{1} = LustreVar(L_dimjump{1},indexDataType);
    %body = sprintf('%s%s = %d;\n\t', body,L_dimjump{1}, dimJump(1));
    body{1} = LustreEq(L_dimjump{1},IntExpr(dimJump(1)));
    for i=2:NumberOfTableDimensions
        L_dimjump{i} =  VarIdExpr(sprintf('%s_dimJump_%d',blk_name,i));
        %vars = sprintf('%s\t%s:%s;\n',vars,L_dimjump{i},indexDataType);
        vars{i} = LustreVar(L_dimjump{i},indexDataType);
        for j=1:i-1
            dimJump(i) = dimJump(i)*numel(BreakpointsForDimension{j});
        end
        %body = sprintf('%s%s = %d;\n\t', body,L_dimjump{i}, dimJump(i));
        body{i} = LustreEq(L_dimjump{i},IntExpr(dimJump(i)));
        Ast_dimJump{i} = IntExpr(dimJump(i));
    end
end

