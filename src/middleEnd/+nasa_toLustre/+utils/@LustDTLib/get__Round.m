% Round Rounds number to the nearest representable value.
% If a tie occurs, rounds positive numbers toward positive infinity
% and rounds negative numbers toward negative infinity.
% Equivalent to the Fixed-Point Designer round function.
function [node, external_nodes, opens, abstractedNodes] = get__Round(lus_backend, varargin)
    if LusBackendType.isKIND2(lus_backend)
        import nasa_toLustre.lustreAst.*
        opens = {};
        abstractedNodes = {};
        external_nodes = {'LustDTLib__Floor', 'LustDTLib__Ceiling'};
        node = LustreNode();
        node.setName('_Round');
        node.setInputs(LustreVar('x', 'real'));
        node.setOutputs(LustreVar('y', 'int'));
        node.setIsMain(false);
        ifAst = IteExpr(...
            BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), RealExpr('0.0')),...
            IntExpr(0), ...
            IteExpr(...
            BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), RealExpr('0.0')), ...
            NodeCallExpr('_Floor', ...
            BinaryExpr(BinaryExpr.PLUS, VarIdExpr('x'), RealExpr('0.5'))), ...
            NodeCallExpr('_Ceiling', ...
            BinaryExpr(BinaryExpr.MINUS, VarIdExpr('x'), RealExpr('0.5')))));
        node.setBodyEqs(LustreEq(VarIdExpr('y'), ifAst));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
end