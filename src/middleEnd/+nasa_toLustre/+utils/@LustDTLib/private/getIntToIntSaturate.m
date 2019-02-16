function [node, external_nodes, opens, abstractedNodes] = getIntToIntSaturate(dt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes = {};
    node_name = sprintf('int_to_%s_saturate', dt);
    % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    % format = [format, 'y= if x > %d then %d  \n\t'];
    % format = [format, 'else if x < %d then %d \n\telse x;\ntel\n\n'];
    %
    % node = sprintf(format, node_name, v_max, v_max, v_min, v_min);
    
    v_max = IntExpr(intmax(dt));
    v_min = IntExpr(intmin(dt));
    conds{1} = BinaryExpr(BinaryExpr.GT, VarIdExpr('x'),v_max);
    conds{2} = BinaryExpr(BinaryExpr.LT, VarIdExpr('x'), v_min);
    thens{1} = v_max;
    thens{2} = v_min;
    thens{3} = VarIdExpr('x');
    bodyElts{1} =   LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(conds, thens));
    
    node = LustreNode();
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
end