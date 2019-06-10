function [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseUnsigned(n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        opens = {};
    abstractedNodes = {};
    external_nodes = {};
    node_name = strcat('_NOT_Bitwise_Unsigned_', num2str(n));
    v2_pown = 2^n - 1;
    %format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    %format = [format, 'y=  %d - x ;\ntel\n\n'];
    %node = sprintf(format, node_name,v2_pown);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, nasa_toLustre.lustreAst.IntExpr(v2_pown), nasa_toLustre.lustreAst.VarIdExpr('x'))...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
