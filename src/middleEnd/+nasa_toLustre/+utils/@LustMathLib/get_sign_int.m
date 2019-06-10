%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [node, external_nodes_i, opens, abstractedNodes] = get_sign_int(varargin)
        opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
        {nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr('0')), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr('0'))}, ...
        {nasa_toLustre.lustreAst.IntExpr('1'), nasa_toLustre.lustreAst.IntExpr('-1'), nasa_toLustre.lustreAst.IntExpr('0')})...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName('sign_int');
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
