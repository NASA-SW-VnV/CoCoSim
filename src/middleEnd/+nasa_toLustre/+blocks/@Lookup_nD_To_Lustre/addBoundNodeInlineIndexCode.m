function [body, vars, boundingi] = ...
    addBoundNodeInlineIndexCode(index_node,Ast_dimJump,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % This function find inline index of bounding nodes
    indexDataType = 'int';
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    numBoundNodes = 2^NumberOfTableDimensions;
%     shapeNodeSign = ...
%         nasa_toLustre.blocks.Lookup_nD_To_Lustre.getShapeBoundingNodeSign(...
%         NumberOfTableDimensions);    
    body = cell(1,numBoundNodes);     
    vars = cell(1,numBoundNodes);            
    % defining boundingi{i}
    boundingi = cell(1,numBoundNodes);
    for i=1:numBoundNodes
        boundingi{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('bound_node_index_inline%d',i));
    end    

    for i=1:numBoundNodes
        %dimSign = shapeNodeSign(i,:);
        % declaring boundingi{i}
        boundingi{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('bound_node_index_inline%d',i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            boundingi{i},indexDataType);

        %value = '0';
        terms = cell(1,NumberOfTableDimensions);
        for j=1:NumberOfTableDimensions
            % dimSign(j): 0 is low, 1: high
            node2bin = strcat('000000', dec2bin(i-1));
            if strcmp(node2bin(end-j+1), '0') %dimSign(j) == -1
                curIndex =  index_node{j,1};
            else
                curIndex =  index_node{j,2};
            end
            % check logic here
            if strcmp(blkParams.InterpMethod,'Flat')  % doesn't use bound node 2
                curIndex =  index_node{j,1};
            end
            if j==1
                terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    curIndex,Ast_dimJump{j});
            else
                terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                    curIndex, ...
                    nasa_toLustre.lustreAst.IntExpr(1)),...
                    Ast_dimJump{j});
            end
        end
        if NumberOfTableDimensions == 1
            value = terms{1};
        else
            value = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.PLUS,terms);
        end
        body{i} = nasa_toLustre.lustreAst.LustreEq(boundingi{i},value);

    end
    
end