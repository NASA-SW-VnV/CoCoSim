function [node, external_nodes_i, opens, abstractedNodes] = getBoolTo(dt)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    
    node_name = strcat('bool_to_', dt);
    if strcmp(dt, 'int')
        zero = IntExpr(0);
        one = IntExpr(1);
    else
        zero = RealExpr('0.0');
        one = RealExpr('1.0');
    end
    %format = 'node %s (x: bool)\nreturns(y:%s);\nlet\n\t y= if x then %s else %s;\ntel\n\n';
    %node = sprintf(format, node_name, dt, one, zero);
    
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr(VarIdExpr('x'),...
        one,...
        zero)...
        );
    
    node = LustreNode();
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'bool'));
    node.setOutputs(LustreVar('y', dt));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end