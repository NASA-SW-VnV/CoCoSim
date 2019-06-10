function [node, external_nodes, opens, abstractedNodes] = getIntToInt(dt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        opens = {};
    abstractedNodes = {};
    v_max = double(intmax(dt));% we need v_max as double variable
    v_min = double(intmin(dt));% we need v_min as double variable
    nb_int = (v_max - v_min + 1);
    node_name = strcat('int_to_', dt);
    
    % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    % format = [format, 'y= if x > v_max then v_min + rem_int_int((x - v_max - 1),nb_int) \n\t'];
    % format = [format, 'else if x < v_min then v_max + rem_int_int((x - (v_min) + 1),nb_int) \n\telse x;\ntel\n\n'];
    % node = sprintf(format, node_name, v_max, v_min, v_max, nb_int,...
    %     v_min, v_max, v_min, nb_int);
    
    conds{1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
        nasa_toLustre.lustreAst.VarIdExpr('x'), ...
        nasa_toLustre.lustreAst.IntExpr(v_max));
    conds{2} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
        nasa_toLustre.lustreAst.VarIdExpr('x'), ...
        nasa_toLustre.lustreAst.IntExpr(v_min));
    %  %d + rem_int_int((x - %d - 1),%d)
    thens{1} = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
        nasa_toLustre.lustreAst.IntExpr(v_min),...
        nasa_toLustre.lustreAst.NodeCallExpr('rem_int_int',...
        {nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
        {nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(v_max), nasa_toLustre.lustreAst.IntExpr(1)}),...
        nasa_toLustre.lustreAst.IntExpr(nb_int)}));
    %d + rem_int_int((x - (%d) + 1),%d)
    if v_min == 0, neg_vmin = 0; else, neg_vmin = -v_min; end
    thens{2} = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
        nasa_toLustre.lustreAst.IntExpr(v_max),...
        nasa_toLustre.lustreAst.NodeCallExpr('rem_int_int', ...
        {nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
        nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
        {nasa_toLustre.lustreAst.VarIdExpr('x'),...
        nasa_toLustre.lustreAst.IntExpr(neg_vmin),...
        nasa_toLustre.lustreAst.IntExpr(1)}),...
        nasa_toLustre.lustreAst.IntExpr(nb_int)}));
    thens{3} = nasa_toLustre.lustreAst.VarIdExpr('x');
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
    
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    external_nodes = {strcat('LustMathLib_', 'rem_int_int')};
    
end
