function node = randomNode(blk_name, minimum, maximum, r, lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(blk_name);
    node.setInputs(nasa_toLustre.lustreAst.LustreVar('b', 'bool'));
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('r', 'real'));
    if LusBackendType.isKIND2(lus_backend)
        contractElts{1} = nasa_toLustre.lustreAst.ContractGuaranteeExpr('', ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, ....
            nasa_toLustre.lustreAst.RealExpr(minimum), nasa_toLustre.lustreAst.VarIdExpr('r')), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, ...
            nasa_toLustre.lustreAst.VarIdExpr('r'), nasa_toLustre.lustreAst.RealExpr(maximum))));
        contract = nasa_toLustre.lustreAst.LustreContract();
        contract.setBodyEqs(contractElts);
        node.setLocalContract(contract);
        node.setIsImported(true);
    else
        node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('r'), ...
            nasa_toLustre.blocks.UniformRandomNumber_To_Lustre.getRandomValues(r, 1)));
    end



end
