function [node, external_nodes, opens, abstractedNodes] = get__Floor(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if LusBackendType.isKIND2(lus_backend)
        abstractedNodes = {};
        import nasa_toLustre.lustreAst.*
        opens = {};
        external_nodes = {};
        node = LustreNode();
        node.setName('_Floor');
        node.setInputs(LustreVar('x', 'real'));
        node.setOutputs(LustreVar('y', 'int'));
        node.setIsMain(false);
        node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
            UnaryExpr(UnaryExpr.INT, VarIdExpr('x'))));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
    
end