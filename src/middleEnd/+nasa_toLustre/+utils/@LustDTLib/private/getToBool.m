function [node, external_nodes_i, opens, abstractedNodes] = getToBool(dt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
        opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    node_name = strcat(dt, '_to_bool');
    if strcmp(dt, 'int')
        zero = nasa_toLustre.lustreAst.IntExpr(0);
    else
        zero = nasa_toLustre.lustreAst.RealExpr('0.0');
    end
    %format = 'node %s (x: %s)\nreturns(y:bool);\nlet\n\t y= (x <> %s);\ntel\n\n';
    %node = sprintf(format, node_name, dt, zero);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.NEQ, ...
        nasa_toLustre.lustreAst.VarIdExpr('x'),...
        zero));
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', dt));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'bool'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
end
