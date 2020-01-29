%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function [node, external_nodes_i, opens, abstractedNodes] = get_sign_real(varargin)
        opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
        {nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.0')), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.0'))}, ...
        {nasa_toLustre.lustreAst.RealExpr('1.0'), nasa_toLustre.lustreAst.RealExpr('-1.0'), nasa_toLustre.lustreAst.RealExpr('0.0')})...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName('sign_real');
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'real'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
