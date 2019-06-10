function [node, external_nodes, opens, abstractedNodes] = getXORBitwiseUnsigned(n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        opens = {};
    abstractedNodes = {};
    external_nodes = {};
    
    %code = {};
    %code{1} = sprintf('((x + y) mod 2)');
    args = cell(1, n);
    args{1} =   ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD,...
        nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
        nasa_toLustre.lustreAst.VarIdExpr('x'), ...
        nasa_toLustre.lustreAst.VarIdExpr('y')...
        ),...
        nasa_toLustre.lustreAst.IntExpr(2));
    for i=1:n-1
        v2_pown = 2^i;
        %code{end+1} = sprintf('%d*(((x / %d) + (y / %d)) mod 2)', v2_pown, v2_pown, v2_pown);
        x_term = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(v2_pown));
        y_term = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, nasa_toLustre.lustreAst.VarIdExpr('y'), nasa_toLustre.lustreAst.IntExpr(v2_pown));
        args{i + 1} =   ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ...
            nasa_toLustre.lustreAst.IntExpr(v2_pown), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD,...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, x_term, y_term),...
            nasa_toLustre.lustreAst.IntExpr(2))...
            );
    end
    %code = MatlabUtils.strjoin(code, ' \n\t+ ');
    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS, args);
    node_name = strcat('_XOR_Bitwise_Unsigned_', num2str(n));
    
    % format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
    % format = [format, 'z = %s;\ntel\n\n'];
    % node = sprintf(format, node_name, code);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('z'), rhs);
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', 'int'), nasa_toLustre.lustreAst.LustreVar('y', 'int')});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
