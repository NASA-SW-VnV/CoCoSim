function [body, vars,u_node] = addUnodeCode(...
        boundingi,blkParams, readTableNodeName, readTableInputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
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
            vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
                u_node{i},'real');
            % defining u_node{i}
            readTableInputs{1} = boundingi{i};
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(u_node{i}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(readTableNodeName, readTableInputs));
        end
        
    end
end

