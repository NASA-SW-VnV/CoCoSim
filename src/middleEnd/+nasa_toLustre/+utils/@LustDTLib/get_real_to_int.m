function [node, external_nodes, opens, abstractedNodes] = get_real_to_int(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    if LusBackendType.isKIND2(lus_backend)
                opens = {};
        abstractedNodes = {};
        external_nodes = {'LustDTLib__Floor', 'LustDTLib__Ceiling'};
        node = nasa_toLustre.lustreAst.LustreNode();
        node.setName('real_to_int');
        node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
        node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
        node.setIsMain(false);
        ifAst = nasa_toLustre.lustreAst.IteExpr(...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.0')), ...
            nasa_toLustre.lustreAst.NodeCallExpr('_Floor', nasa_toLustre.lustreAst.VarIdExpr('x')), ...
            nasa_toLustre.lustreAst.NodeCallExpr('_Ceiling', nasa_toLustre.lustreAst.VarIdExpr('x')));
        node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ifAst));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
end
