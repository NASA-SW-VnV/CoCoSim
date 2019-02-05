function [node, external_nodes_i, opens, abstractedNodes] = getToBool(dt)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    node_name = strcat(dt, '_to_bool');
    if strcmp(dt, 'int')
        zero = IntExpr(0);
    else
        zero = RealExpr('0.0');
    end
    %format = 'node %s (x: %s)\nreturns(y:bool);\nlet\n\t y= (x <> %s);\ntel\n\n';
    %node = sprintf(format, node_name, dt, zero);
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        BinaryExpr(BinaryExpr.NEQ, ...
        VarIdExpr('x'),...
        zero));
    
    node = LustreNode();
    node.setName(node_name);
    node.setInputs(LustreVar('x', dt));
    node.setOutputs(LustreVar('y', 'bool'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
end