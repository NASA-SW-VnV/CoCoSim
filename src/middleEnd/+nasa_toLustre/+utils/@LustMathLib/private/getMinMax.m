function [node, external_nodes_i, opens, abstractedNodes] = getMinMax(minOrMAx, dt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    node_name = strcat('_', minOrMAx, '_', dt);
    if strcmp(minOrMAx, 'min')
        op = nasa_toLustre.lustreAst.BinaryExpr.LT;
    else
        op = nasa_toLustre.lustreAst.BinaryExpr.GT;
    end
    %node_format = 'node %s (x, y: %s)\nreturns(z:%s);\nlet\n\t z = if (x %s y) then x else y;\ntel\n\n';
    %node  = sprintf(node_format, node_name, dt, dt, op);
    bodyElts = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        nasa_toLustre.lustreAst.IteExpr(...
        nasa_toLustre.lustreAst.BinaryExpr(op, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')), ...
        nasa_toLustre.lustreAst.VarIdExpr('x'), ...
        nasa_toLustre.lustreAst.VarIdExpr('y'))...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', dt), nasa_toLustre.lustreAst.LustreVar('y', dt)});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', dt));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
