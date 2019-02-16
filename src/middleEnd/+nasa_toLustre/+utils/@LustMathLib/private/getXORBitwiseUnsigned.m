function [node, external_nodes, opens, abstractedNodes] = getXORBitwiseUnsigned(n)
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
    
    %code = {};
    %code{1} = sprintf('((x + y) mod 2)');
    args = cell(1, n);
    args{1} =   ...
        BinaryExpr(BinaryExpr.MOD,...
        BinaryExpr(...
        BinaryExpr.PLUS, ...
        VarIdExpr('x'), ...
        VarIdExpr('y')...
        ),...
        IntExpr(2));
    for i=1:n-1
        v2_pown = 2^i;
        %code{end+1} = sprintf('%d*(((x / %d) + (y / %d)) mod 2)', v2_pown, v2_pown, v2_pown);
        x_term = BinaryExpr(...
            BinaryExpr.DIVIDE, VarIdExpr('x'), IntExpr(v2_pown));
        y_term = BinaryExpr(...
            BinaryExpr.DIVIDE, VarIdExpr('y'), IntExpr(v2_pown));
        args{i + 1} =   ...
            BinaryExpr(...
            BinaryExpr.MULTIPLY, ...
            IntExpr(v2_pown), ...
            BinaryExpr(BinaryExpr.MOD,...
            BinaryExpr(BinaryExpr.PLUS, x_term, y_term),...
            IntExpr(2))...
            );
    end
    %code = MatlabUtils.strjoin(code, ' \n\t+ ');
    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, args);
    node_name = strcat('_XOR_Bitwise_Unsigned_', num2str(n));
    
    % format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
    % format = [format, 'z = %s;\ntel\n\n'];
    % node = sprintf(format, node_name, code);
    bodyElts{1} = LustreEq(VarIdExpr('z'), rhs);
    node = LustreNode();
    node.setName(node_name);
    node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
    node.setOutputs(LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end