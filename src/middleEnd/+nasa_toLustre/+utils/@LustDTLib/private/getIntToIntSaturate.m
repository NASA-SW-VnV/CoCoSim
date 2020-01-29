function [node, external_nodes, opens, abstractedNodes] = getIntToIntSaturate(dt)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    global CoCoSimPreferences
    if isempty(CoCoSimPreferences)
        CoCoSimPreferences.forceTypeCastingOfInt = true;
    end
    opens = {};
    abstractedNodes = {};
    external_nodes = {};
    node_name = sprintf('int_to_%s_saturate', dt);
    % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    % format = [format, 'y= if x > %d then %d  \n\t'];
    % format = [format, 'else if x < %d then %d \n\telse x;\ntel\n\n'];
    %
    % node = sprintf(format, node_name, v_max, v_max, v_min, v_min);
    if CoCoSimPreferences.forceTypeCastingOfInt
        v_max = nasa_toLustre.lustreAst.IntExpr(intmax(dt));
        v_min = nasa_toLustre.lustreAst.IntExpr(intmin(dt));
        conds{1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'),v_max);
        conds{2} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, nasa_toLustre.lustreAst.VarIdExpr('x'), v_min);
        thens{1} = v_max;
        thens{2} = v_min;
        thens{3} = nasa_toLustre.lustreAst.VarIdExpr('x');
        bodyElts{1} =   nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr('y'), ...
            nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
    else
        bodyElts{1} = nasa_toLustre.lustreAst.LustreComment('Type-casting was disabled. See Tools -> CoCoSim -> Preferences -> NASA compiler preferences.');
        bodyElts{2} =   nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr('y'), ...
            nasa_toLustre.lustreAst.VarIdExpr('x'));
    end
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'int'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    
end
