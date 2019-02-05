function [node, external_nodes, opens, abstractedNodes] = get__Floor(lus_backend, varargin)
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