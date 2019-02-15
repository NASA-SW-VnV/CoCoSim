function node = randomNode(blk_name, r, lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    node = LustreNode();
    node.setName(blk_name);
    node.setInputs(LustreVar('b', 'bool'));
    node.setOutputs(LustreVar('r', 'real'));
    if LusBackendType.isKIND2(lus_backend)
        contractElts{1} = ContractGuaranteeExpr('', ...
            BinaryExpr(BinaryExpr.AND, ...
            BinaryExpr(BinaryExpr.LTE, RealExpr(min(r)), VarIdExpr('r')), ...
            BinaryExpr(BinaryExpr.LTE, VarIdExpr('r'), RealExpr(max(r)))));
        contract = LustreContract();
        contract.setBodyEqs(contractElts);
        node.setLocalContract(contract);
        node.setIsImported(true);
    else
        node.setBodyEqs(LustreEq(VarIdExpr('r'), ...
            RandomNumber_To_Lustre.getRandomValues(r, 1)));
    end



end
