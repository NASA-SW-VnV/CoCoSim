
function addExtenal_node(obj, nodeAst)
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

