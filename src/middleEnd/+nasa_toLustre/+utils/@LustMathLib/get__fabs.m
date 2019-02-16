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
