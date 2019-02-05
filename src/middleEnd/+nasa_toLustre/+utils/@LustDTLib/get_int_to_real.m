function [node, external_nodes, opens, abstractedNodes] = get_int_to_real(lus_backend, varargin)
    if LusBackendType.isKIND2(lus_backend)
        import nasa_toLustre.lustreAst.*
        opens = {};
        abstractedNodes = {};
        external_nodes = {};
        node = LustreNode();
        node.setName('int_to_real');
        node.setInputs(LustreVar('x', 'int'));
        node.setOutputs(LustreVar('y', 'real'));
        node.setIsMain(false);
        node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
            UnaryExpr(UnaryExpr.REAL, VarIdExpr('x'))));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
end