function node = randomNode(blk_name, r, lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(blk_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('b', 'bool'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('r', 'real'));
    if LusBackendType.isKIND2(lus_backend)
        contractElts{1} = nasa_toLustre.lustreAst.ContractGuaranteeExpr('', ...
            nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.AND, ...
            nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.LTE, nasa_toLustre.lustreAst.RealExpr(min(r)), nasa_toLustre.lustreAst.VarIdExpr('r')), ...
            nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.LTE, nasa_toLustre.lustreAst.VarIdExpr('r'), nasa_toLustre.lustreAst.RealExpr(max(r)))));
        contract = nasa_toLustre.lustreAst.LustreContract();
        contract.setBodyEqs(contractElts);
        node.setLocalContract(contract);
        node.setIsImported(true);
    else
        node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('r'), ...
            nasa_toLustre.blocks.RandomNumber_To_Lustre.getRandomValues(r, 1)));
    end



end
