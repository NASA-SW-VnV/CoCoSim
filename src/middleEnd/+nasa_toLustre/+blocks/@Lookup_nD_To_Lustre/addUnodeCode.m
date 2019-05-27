function [body, vars,u_node] = addUnodeCode(...
        boundingi,table_elem,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function defines and calculating shape function values for the
    % interpolation point
    body = {};   % body may grow if ~directLookup
    vars = {};
    u_node = {};
    
    numBoundNodes = 2^blkParams.NumberOfTableDimensions;
    if ~blkParams.directLookup
        for i=1:numBoundNodes
            vName = sprintf('u_node_%d',i);
            u_node{i} = nasa_toLustre.lustreAst.VarIdExpr(vName);
            % First SOLUTION, Direct search O(n)
            %             vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            %                 u_node{i},'real');
            %             % defining u_node{i}
            %             conds = cell(1,numel(table_elem)-1);
            %             thens = cell(1,numel(table_elem));
            %             for j=1:numel(table_elem)-1
            %                 conds{j} = nasa_toLustre.lustreAst.BinaryExpr(...
            %                     nasa_toLustre.lustreAst.BinaryExpr.EQ,...
            %                     boundingi{i},nasa_toLustre.lustreAst.IntExpr(j));
            %                 thens{j} = table_elem{j};
            %             end
            %             thens{numel(table_elem)} = table_elem{numel(table_elem)};
            %             rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
            %             body{end+1} = nasa_toLustre.lustreAst.LustreEq(u_node{i},rhs);
            
            
            % Second solution: Binary search O(log(n))
            [body, vars] = nasa_toLustre.lustreAst.IteExpr.binarySearch(...
                table_elem, boundingi{i}, vName,...
                'real', [], body, vars, vName);
        end
        
    end
end

