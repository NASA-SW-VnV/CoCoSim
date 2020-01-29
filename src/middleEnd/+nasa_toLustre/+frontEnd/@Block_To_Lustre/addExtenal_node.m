function addExtenal_node(obj, nodeAst)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    if iscell(nodeAst)
        obj.external_nodes = [obj.external_nodes, nodeAst];
    elseif ~ischar(nodeAst) && numel(nodeAst) > 1
        for i=1:numel(nodeAst)
            obj.external_nodes{end +1} = nodeAst(i);
        end
    else
        obj.external_nodes{end +1} = nodeAst;
    end
end

