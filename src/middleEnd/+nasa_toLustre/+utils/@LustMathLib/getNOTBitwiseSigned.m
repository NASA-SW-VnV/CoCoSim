function [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseSigned()
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes = {};
    node_name = strcat('_NOT_Bitwise_Signed');
    %format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    %format = [format, 'y=   - x - 1;\ntel\n\n'];
    %node = sprintf(format, node_name);
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        BinaryExpr(BinaryExpr.MINUS, ...
        UnaryExpr(UnaryExpr.NEG ,VarIdExpr('x')),...
        IntExpr(1) )...
        );
    node = LustreNode();
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end