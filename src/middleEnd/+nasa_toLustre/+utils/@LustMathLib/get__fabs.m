function [node, external_nodes_i, opens, abstractedNodes] = get__fabs(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    
    bodyElts{1} = LustreEq(...
        VarIdExpr('z'), ...
        IteExpr(...
        BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), RealExpr('0.0')), ...
        VarIdExpr('x'), ...
        UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
        );
    node = LustreNode();
    node.setName('_fabs');
    node.setInputs(LustreVar('x', 'real'));
    node.setOutputs(LustreVar('z', 'real'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end