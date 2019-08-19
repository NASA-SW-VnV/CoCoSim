classdef MF2LusUtils
    %MF2LUSUTILS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %         Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        [code, exp_dt, dim, extra_code] = allAnyFun_To_Lustre(tree, args, op)
        
        [code, exp_dt, dim, extra_code] = binaryFun_To_Lustre(tree, args, op)
        
        [code, dim] = mtimesFun_To_Lustre(x, x_dim, y, y_dim)
        
        [code, exp_dt, dim] = numFun_To_Lustre(tree, args)
        
        [while_node] = abstract_statements_block(tree, args, type)
        
        [main_node] = getStatementsBlockAsNode(tree, args, type)
        
        [IDs] = getAssignmentLeftIDs(tree)
        
        vars = addLocalVars(args, exp_dt, n)
        
    end
end

