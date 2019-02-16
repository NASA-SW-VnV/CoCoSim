function [node, external_nodes, opens, abstractedNodes] = getNANDBitwiseUnsigned(n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    notNode = sprintf('_NOT_Bitwise_Unsigned_%d', n);
    UnsignedNode =  sprintf('_AND_Bitwise_Unsigned_%d', n);
    external_nodes = {strcat('LustMathLib_', notNode),...
        strcat('LustMathLib_', UnsignedNode)};
    
    node_name = sprintf('_NAND_Bitwise_Unsigned_%d', n);
    %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
    %             format = [format, 'z = %s(%s(x, y));\ntel\n\n'];
    %             node = sprintf(format, node_name, notNode, UnsignedNode);
    bodyElts{1} = LustreEq(...
        VarIdExpr('z'), ...
        NodeCallExpr(notNode, ...
        NodeCallExpr(UnsignedNode, ...
        {VarIdExpr('x'), VarIdExpr('y')}))...
        );
    node = LustreNode();
    node.setName(node_name);
    node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
    node.setOutputs(LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end