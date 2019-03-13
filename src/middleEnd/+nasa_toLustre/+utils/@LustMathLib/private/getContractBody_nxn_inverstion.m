function contractBody = getContractBody_nxn_inverstion(n,inputs,outputs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % guarantee code     A*A_inv = I
    % A*A_inv(ij) = 1.0 if i==j, = 0.0 if i!=j
    contractBody = cell(1, n*n);
    codeIndex = 0;
    zero = nasa_toLustre.lustreAst.RealExpr(0.0);
    one = nasa_toLustre.lustreAst.RealExpr(1.0);
    
    for i=1:n      %i is row of result matrix
        for j=1:n      %j is column of result matrix
            terms = cell(1,n);
            for k=1:n
                A_index = sub2ind([n,n],i,k);
                A_inv_index = sub2ind([n,n],k,j);
                
                terms{k} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ...
                    inputs{1,A_index},...
                    outputs{1,A_inv_index});
            end
            lhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,terms);
            if i==j
                rhs = one;
            else
                rhs = zero;
            end
            codeIndex = codeIndex + 1;
            contractBody{codeIndex} = nasa_toLustre.lustreAst.ContractGuaranteeExpr('',nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ,lhs, rhs));
        end
        
    end
end
