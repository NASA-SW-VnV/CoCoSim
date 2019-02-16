%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Zero(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
    % format = '--Rounds positive and negative numbers toward positive infinity\n ';
    % format = [format,  'node int_div_Zero (x, y: int)\nreturns(z:int);\nlet\n\t'];
    % format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
    % format = [format, 'else if x mod y = 0 then x/y\n\t'];
    % format = [format, 'else if (abs_int(y) > abs_int(x)) then 0 \n\t'];
    % format = [format, 'else if (x>0) then x/y \n\t'];
    % format = [format, 'else (-x)/(-y);\ntel\n\n'];
    % node = sprintf(format);
    %y = 0
    conds{1} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0));
    %if x>0 then 2147483647 else -2147483648
    thens{1} = IteExpr(...
        BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), IntExpr(0)),...
        IntExpr(2147483647), IntExpr(-2147483648),...
        true);
    % x mod y = 0
    conds{2} = BinaryExpr(...
        BinaryExpr.EQ, ...
        BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')), ...
        IntExpr(0));
    % x/y
    thens{2} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
    % (abs_int(y) > abs_int(x))
    conds{3} =  BinaryExpr(BinaryExpr.GT, ...
        NodeCallExpr('abs_int', VarIdExpr('y')),...
        NodeCallExpr('abs_int', VarIdExpr('x')));
    % 0
    thens{3} = IntExpr(0);
    % (x>0)
    conds{4} =  BinaryExpr(BinaryExpr.GT, ...
        VarIdExpr('x'),...
        IntExpr(0));
    % x/y
    thens{4} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
    % (-x)/(-y)
    thens{5} = BinaryExpr(...
        BinaryExpr.DIVIDE, ...
        UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')), ...
        UnaryExpr(UnaryExpr.NEG, VarIdExpr('y')));
    bodyElts{1} = LustreEq(...
        VarIdExpr('z'), ...
        IteExpr.nestedIteExpr(conds, thens)...
        );
    node = LustreNode();
    node.setMetaInfo('Rounds positive and negative numbers toward positive infinity');
    node.setName('int_div_Zero');
    node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
    node.setOutputs(LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
