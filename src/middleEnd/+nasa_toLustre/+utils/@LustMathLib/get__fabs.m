function [node, external_nodes_i, opens, abstractedNodes] = get__fabs(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        nasa_toLustre.lustreAst.IteExpr(...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.0')), ...
        nasa_toLustre.lustreAst.VarIdExpr('x'), ...
        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, nasa_toLustre.lustreAst.VarIdExpr('x')))...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName('_fabs');
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'real'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
