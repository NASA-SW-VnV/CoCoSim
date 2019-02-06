function [node, external_nodes_i, opens, abstractedNodes] = getMinMax(minOrMAx, dt)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    node_name = strcat('_', minOrMAx, '_', dt);
    if strcmp(minOrMAx, 'min')
        op = BinaryExpr.LT;
    else
        op = BinaryExpr.GT;
    end
    %node_format = 'node %s (x, y: %s)\nreturns(z:%s);\nlet\n\t z = if (x %s y) then x else y;\ntel\n\n';
    %node  = sprintf(node_format, node_name, dt, dt, op);
    bodyElts = LustreEq(...
        VarIdExpr('z'), ...
        IteExpr(...
        BinaryExpr(op, VarIdExpr('x'), VarIdExpr('y')), ...
        VarIdExpr('x'), ...
        VarIdExpr('y'))...
        );
    node = LustreNode();
    node.setName(node_name);
    node.setInputs({LustreVar('x', dt), LustreVar('y', dt)});
    node.setOutputs(LustreVar('z', dt));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end