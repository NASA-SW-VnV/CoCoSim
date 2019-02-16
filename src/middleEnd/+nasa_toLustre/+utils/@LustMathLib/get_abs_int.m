%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [node, external_nodes_i, opens, abstractedNodes] = get_abs_int(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr(...
        BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), IntExpr('0')), ...
        VarIdExpr('x'), ...
        UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
        );
    node = LustreNode();
    node.setName('abs_int');
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
