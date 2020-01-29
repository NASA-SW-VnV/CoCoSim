%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Zero(varargin)
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
    conds{1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('y'), nasa_toLustre.lustreAst.IntExpr(0));
    %if x>0 then 2147483647 else -2147483648
    thens{1} = nasa_toLustre.lustreAst.IteExpr(...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(0)),...
        nasa_toLustre.lustreAst.IntExpr(2147483647), nasa_toLustre.lustreAst.IntExpr(-2147483648),...
        true);
    % x mod y = 0
    conds{2} = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')), ...
        nasa_toLustre.lustreAst.IntExpr(0));
    % x/y
    thens{2} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y'));
    % (abs_int(y) > abs_int(x))
    conds{3} =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
        nasa_toLustre.lustreAst.NodeCallExpr('abs_int', nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.NodeCallExpr('abs_int', nasa_toLustre.lustreAst.VarIdExpr('x')));
    % 0
    thens{3} = nasa_toLustre.lustreAst.IntExpr(0);
    % (x>0)
    conds{4} =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
        nasa_toLustre.lustreAst.VarIdExpr('x'),...
        nasa_toLustre.lustreAst.IntExpr(0));
    % x/y
    thens{4} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y'));
    % (-x)/(-y)
    thens{5} = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, nasa_toLustre.lustreAst.VarIdExpr('x')), ...
        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, nasa_toLustre.lustreAst.VarIdExpr('y')));
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens)...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setMetaInfo('Rounds positive and negative numbers toward positive infinity');
    node.setName('int_div_Zero');
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', 'int'), nasa_toLustre.lustreAst.LustreVar('y', 'int')});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
