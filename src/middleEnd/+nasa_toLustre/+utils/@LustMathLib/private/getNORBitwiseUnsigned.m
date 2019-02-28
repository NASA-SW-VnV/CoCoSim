function [node, external_nodes, opens, abstractedNodes] = getNORBitwiseUnsigned(n)
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
    UnsignedNode =  sprintf('_OR_Bitwise_Unsigned_%d', n);
    external_nodes = {strcat('LustMathLib_', notNode),...
        strcat('LustMathLib_', UnsignedNode)};
    
    node_name = sprintf('_NOR_Bitwise_Unsigned_%d', n);
    %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
    %             format = [format, 'z = %s(%s(x, y));\ntel\n\n'];
    %             node = sprintf(format, node_name, notNode, UnsignedNode);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        nasa_toLustre.lustreAst.NodeCallExpr(notNode, ...
        nasa_toLustre.lustreAst.NodeCallExpr(UnsignedNode, ...
        {nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')}))...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', 'int'), nasa_toLustre.lustreAst.LustreVar('y', 'int')});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
