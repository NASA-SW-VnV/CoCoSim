function [node, external_nodes, opens, abstractedNodes] = get_int_to_real(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if LusBackendType.isKIND2(lus_backend)
                opens = {};
        abstractedNodes = {};
        external_nodes = {};
        node = nasa_toLustre.lustreAst.LustreNode();
        node.setName('int_to_real');
        node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
        node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'real'));
        node.setIsMain(false);
        node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.REAL, nasa_toLustre.lustreAst.VarIdExpr('x'))));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
end
