function [body, vars] = addShapeFunctionCode(numBoundNodes,...
        shapeNodeSign,blk_name,indexDataType,table_elem,...
        NumberOfTableDimensions,index_node,Ast_dimJump,skipInterpolation,u_node)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % This function defines and calculating shape function values for the
    % interpolation point
    body = {};   % body may grow if ~skipInterpolation
    vars = cell(1,numBoundNodes);            
    boundingi = cell(1,numBoundNodes);

    for i=1:numBoundNodes
        dimSign = shapeNodeSign(i,:);
        % declaring boundingi{i}
        boundingi{i} = VarIdExpr(sprintf('%s_bound_node_index_%d',blk_name,i));
        %vars = sprintf('%s\t%s:%s;\n',vars,boundingi{i},indexDataType);
        vars{i} = LustreVar(boundingi{i},indexDataType);

        % defining boundingi{i}
        %value = '0';
        terms = cell(1,NumberOfTableDimensions);
        for j=1:NumberOfTableDimensions
            % dimSign(j): -1 is low, 1: high
            if dimSign(j) == -1
                curIndex =  index_node{j,1};
            else
                curIndex =  index_node{j,2};
            end
            if j==1
                %value = sprintf('%s + %s*%d',value,curIndex, dimJump(j));
                terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,curIndex,Ast_dimJump{j});
            else
                %value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j));
                terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,...
                    BinaryExpr(BinaryExpr.MINUS,...
                                curIndex, ...
                                IntExpr(1)),...
                    Ast_dimJump{j});
            end
        end
        %body = sprintf('%s%s = %s;\n\t', body,boundingi{i}, value);
        if NumberOfTableDimensions == 1
            value = terms{1};
        else
            value = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS,terms);
        end
        body{end+1} = LustreEq(boundingi{i},value);

        if ~skipInterpolation
            % defining u_node{i}
            %code = sprintf('%s = \n\t', u_node{i});
            conds = cell(1,numel(table_elem)-1);
            thens = cell(1,numel(table_elem));
            for j=1:numel(table_elem)-1
%                        if j==1
                    %code = sprintf('%s  if(%s = %d) then %s\n\t', code, boundingi{i},j,table_elem{j});
                    conds{j} = BinaryExpr(BinaryExpr.EQ,boundingi{i},IntExpr(j));
                    thens{j} = table_elem{j};
%                         else
%                             %code = sprintf('%s  else if(%s = %d) then %s\n\t', code, boundingi{i},j,table_elem{j});
%                             conds{j} = BinaryExpr(BinaryExpr.EQ,boundingi{i},IntExpr(j));
%                             thens{j} = table_elem{j};                            
%                        end
            end
            %body = sprintf('%s%s  else %s ;\n\t', body,code,table_elem{numel(table_elem)});
            thens{numel(table_elem)} = table_elem{numel(table_elem)};
            rhs = IteExpr.nestedIteExpr(conds, thens);
            body{end+1} = LustreEq(u_node{i},rhs);
        end

    end
end

