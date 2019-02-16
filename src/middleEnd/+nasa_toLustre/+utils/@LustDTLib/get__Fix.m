% Rounds each element of the input signal to the nearest integer towards zero.
function [node, external_nodes, opens, abstractedNodes] = get__Fix(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    import nasa_toLustre.lustreAst.*
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
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(...
        {...
        BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'),RealExpr('0.5')),...
        BinaryExpr(BinaryExpr.GT, VarIdExpr('x'),RealExpr('-0.5'))...
        },...
        {...
        NodeCallExpr('_Floor', VarIdExpr('x')),...
        IntExpr(0),...
        NodeCallExpr('_Ceiling', VarIdExpr('x'))...
        }));
    
    node = LustreNode();
    node.setMetaInfo('Rounds number to the nearest integer towards zero');
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'real'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
    external_nodes = {strcat('LustDTLib_', '_Floor'),...
        strcat('LustDTLib_', '_Ceiling')};
end