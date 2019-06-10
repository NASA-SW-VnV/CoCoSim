function [node, external_nodes_i, opens, abstractedNodes] = getBoolTo(dt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    
    node_name = strcat('bool_to_', dt);
    if strcmp(dt, 'int')
        zero = nasa_toLustre.lustreAst.IntExpr(0);
        one = nasa_toLustre.lustreAst.IntExpr(1);
    else
        zero = nasa_toLustre.lustreAst.RealExpr('0.0');
        one = nasa_toLustre.lustreAst.RealExpr('1.0');
    end
    %format = 'node %s (x: bool)\nreturns(y:%s);\nlet\n\t y= if x then %s else %s;\ntel\n\n';
    %node = sprintf(format, node_name, dt, one, zero);
    
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr(nasa_toLustre.lustreAst.VarIdExpr('x'),...
        one,...
        zero)...
        );
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'bool'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', dt));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
