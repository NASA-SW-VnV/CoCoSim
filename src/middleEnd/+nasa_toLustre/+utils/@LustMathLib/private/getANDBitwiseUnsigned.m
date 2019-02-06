function [node, external_nodes, opens, abstractedNodes] = getANDBitwiseUnsigned(n)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes = {};
    
    args = cell(1, n);
    %code{1} = sprintf('(x mod 2)*(y mod 2)');
    args{1} = BinaryExpr(...
        BinaryExpr.MULTIPLY, ...
        BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), IntExpr(2)), ...
        BinaryExpr(BinaryExpr.MOD, VarIdExpr('y'), IntExpr(2)));
    for i=1:n-1
        v2_pown = 2^i;
        %code{end+1} = sprintf('%d*((x / %d) mod 2)*((y / %d) mod 2)', v2_pown, v2_pown, v2_pown);
        %((x / %d) mod 2)
        x_term = BinaryExpr(...
            BinaryExpr.MOD, ...
            BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), IntExpr(v2_pown)),...
            IntExpr(2));
        %((y / %d) mod 2)
        y_term = BinaryExpr(...
            BinaryExpr.MOD, ...
            BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('y'), IntExpr(v2_pown)),...
            IntExpr(2));
        args{i + 1} = BinaryExpr.BinaryMultiArgs(...
            BinaryExpr.MULTIPLY, ...
            {IntExpr(v2_pown), x_term, y_term});
    end
    %code = MatlabUtils.strjoin(code, ' \n\t+ ');
    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, args);
    node_name = strcat('_AND_Bitwise_Unsigned_', num2str(n));
    
    %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
    %             format = [format, 'z = %s;\ntel\n\n'];
    %             node = sprintf(format, node_name, code);
    bodyElts = LustreEq(...
        VarIdExpr('z'), ...
        rhs);
    node = LustreNode();
    node.setName(node_name);
    node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
    node.setOutputs(LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end