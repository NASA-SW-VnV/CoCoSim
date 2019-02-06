function contractBody = getContractBody_nxn_inverstion(n,inputs,outputs)
    import nasa_toLustre.lustreAst.*
    % guarantee code     A*A_inv = I
    % A*A_inv(ij) = 1.0 if i==j, = 0.0 if i!=j
    contractBody = cell(1, n*n);
    codeIndex = 0;
    zero = RealExpr(0.0);
    one = RealExpr(1.0);
    
    for i=1:n      %i is row of result matrix
        for j=1:n      %j is column of result matrix
            terms = cell(1,n);
            for k=1:n
                A_index = sub2ind([n,n],i,k);
                A_inv_index = sub2ind([n,n],k,j);
                
                terms{k} = BinaryExpr(BinaryExpr.MULTIPLY, ...
                    inputs{1,A_index},...
                    outputs{1,A_inv_index});
            end
            lhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS,terms);
            if i==j
                rhs = one;
            else
                rhs = zero;
            end
            codeIndex = codeIndex + 1;
            contractBody{codeIndex} = ContractGuaranteeExpr('',BinaryExpr(BinaryExpr.EQ,lhs, rhs));
        end
        
    end
end