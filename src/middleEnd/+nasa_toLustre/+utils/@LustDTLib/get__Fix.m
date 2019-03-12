% Rounds each element of the input signal to the nearest integer towards zero.
function [node, external_nodes, opens, abstractedNodes] = get__Fix(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        opens = {};
    abstractedNodes = {};
    % format = '--Rounds number to the nearest integer towards zero.\n';
    % format = [ format ,'node _Fix (x: real)\nreturns(y:int);\nlet\n\t'];
    % format = [ format , 'y = if (x >= 0.5) then _Floor(x)\n\t\t'];
    % format = [ format , ' else if (x > -0.5) then 0 \n\t\t'];
    % format = [ format , ' else _Ceiling(x);'];
    % format = [ format , '\ntel\n\n'];
    % node = sprintf(format);
    
    node_name = '_Fix';
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
        {...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, nasa_toLustre.lustreAst.VarIdExpr('x'),nasa_toLustre.lustreAst.RealExpr('0.5')),...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'),nasa_toLustre.lustreAst.RealExpr('-0.5'))...
        },...
        {...
        nasa_toLustre.lustreAst.NodeCallExpr('_Floor', nasa_toLustre.lustreAst.VarIdExpr('x')),...
        nasa_toLustre.lustreAst.IntExpr(0),...
        nasa_toLustre.lustreAst.NodeCallExpr('_Ceiling', nasa_toLustre.lustreAst.VarIdExpr('x'))...
        }));
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setMetaInfo('Rounds number to the nearest integer towards zero');
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
    external_nodes = {strcat('LustDTLib_', '_Floor'),...
        strcat('LustDTLib_', '_Ceiling')};
end
