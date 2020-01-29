% Nearest Rounds number to the nearest representable value.
%If a tie occurs, rounds toward positive infinity. Equivalent to the Fixed-Point Designer nearest function.
function [node, external_nodes, opens, abstractedNodes] = get__Nearest(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
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
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr(nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE,...
        nasa_toLustre.lustreAst.NodeCallExpr('_fabs', nasa_toLustre.lustreAst.VarIdExpr('x')),...
        nasa_toLustre.lustreAst.RealExpr('0.5')),... % cond
        nasa_toLustre.lustreAst.NodeCallExpr('_Floor', ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
        nasa_toLustre.lustreAst.VarIdExpr('x'),...
        nasa_toLustre.lustreAst.RealExpr('0.5'))),...
        nasa_toLustre.lustreAst.IntExpr(0)));
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setMetaInfo('Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity');
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
    external_nodes = {strcat('LustMathLib_', '_fabs'), ...
        strcat('LustDTLib_', '_Floor'),...
        strcat('LustDTLib_', '_Ceiling')};
end
