function [node, external_nodes, opens, abstractedNodes] = get__Ceiling(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if LusBackendType.isKIND2(lus_backend)
        import nasa_toLustre.lustreAst.*
        opens = {};
        abstractedNodes = {};
        external_nodes = {'LustDTLib__Floor'};
        node = nasa_toLustre.lustreAst.LustreNode();
        node.setName('_Ceiling');
        node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
        node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
        node.setIsMain(false);
        node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, ...
            nasa_toLustre.lustreAst.NodeCallExpr('_Floor', ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, nasa_toLustre.lustreAst.VarIdExpr('x'), false)))));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
    
end
