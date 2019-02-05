% Nearest Rounds number to the nearest representable value.
%If a tie occurs, rounds toward positive infinity. Equivalent to the Fixed-Point Designer nearest function.
function [node, external_nodes, opens, abstractedNodes] = get__Nearest(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    % format = '--Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity\n ';
    % format = [ format ,'node _Nearest (x: real)\nreturns(y:int);\nlet\n\t'];
    % format = [ format , 'y = if (_fabs(x) >= 0.5) then _Floor(x + 0.5)\n\t'];
    % format = [ format , ' else 0;'];
    % format = [ format , '\ntel\n\n'];
    %
    %
    % node = sprintf(format);
    
    node_name = '_Nearest';
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr(BinaryExpr(BinaryExpr.GTE,...
        NodeCallExpr('_fabs', VarIdExpr('x')),...
        RealExpr('0.5')),... % cond
        NodeCallExpr('_Floor', ...
        BinaryExpr(BinaryExpr.PLUS, ...
        VarIdExpr('x'),...
        RealExpr('0.5'))),...
        IntExpr(0)));
    
    node = LustreNode();
    node.setMetaInfo('Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity');
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'real'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
    external_nodes = {strcat('LustMathLib_', '_fabs'), ...
        strcat('LustDTLib_', '_Floor'),...
        strcat('LustDTLib_', '_Ceiling')};
end
