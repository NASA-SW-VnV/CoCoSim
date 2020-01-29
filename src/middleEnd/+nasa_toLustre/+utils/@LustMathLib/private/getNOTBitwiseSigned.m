function [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseSigned()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
        opens = {};
    abstractedNodes = {};
    external_nodes = {};
    node_name = strcat('_NOT_Bitwise_Signed');
    %format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    %format = [format, 'y=   - x - 1;\ntel\n\n'];
    %node = sprintf(format, node_name);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG ,nasa_toLustre.lustreAst.VarIdExpr('x')),...
        nasa_toLustre.lustreAst.IntExpr(1) )...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
