function [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseUnsigned(n)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes = {};
    node_name = strcat('_NOT_Bitwise_Unsigned_', num2str(n));
    v2_pown = 2^n - 1;
    %format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    %format = [format, 'y=  %d - x ;\ntel\n\n'];
    %node = sprintf(format, node_name,v2_pown);
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        BinaryExpr(BinaryExpr.MINUS, IntExpr(v2_pown), VarIdExpr('x'))...
        );
    node = LustreNode();
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end