% Round Rounds number to the nearest representable value.
% If a tie occurs, rounds positive numbers toward positive infinity
% and rounds negative numbers toward negative infinity.
% Equivalent to the Fixed-Point Designer round function.
function [node, external_nodes, opens, abstractedNodes] = get__Round(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if LusBackendType.isKIND2(lus_backend)
                opens = {};
        abstractedNodes = {};
        external_nodes = {'LustDTLib__Floor', 'LustDTLib__Ceiling'};
        node = nasa_toLustre.lustreAst.LustreNode();
        node.setName('_Round');
        node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
        node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
        node.setIsMain(false);
        ifAst = nasa_toLustre.lustreAst.IteExpr(...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.0')),...
            nasa_toLustre.lustreAst.IntExpr(0), ...
            nasa_toLustre.lustreAst.IteExpr(...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.0')), ...
            nasa_toLustre.lustreAst.NodeCallExpr('_Floor', ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.5'))), ...
            nasa_toLustre.lustreAst.NodeCallExpr('_Ceiling', ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.RealExpr('0.5')))));
        node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ifAst));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
end
