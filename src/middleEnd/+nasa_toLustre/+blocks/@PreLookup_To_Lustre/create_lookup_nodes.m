function create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PreLookup
    
    preLookUpExtNode =  ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_pre_lookup_node(...
        lus_backend,blkParams);
    
    wrapperNode = ...
        obj.get_wrapper_node(...
        blk,inputs,outputs,preLookUpExtNode,blkParams);
    
    if LusBackendType.isKIND2(lus_backend) ...
            && ~(LookupType.isLookupDynamic(blkParams.lookupTableType)) ...
            && blkParams.NumberOfTableDimensions <= 3
        contractBody = Lookup_nD_To_Lustre.getContractBody(blkParams,...
            inputs,outputs);
        contract = LustreContract();
        contract.setBodyEqs(contractBody);
        interpolationExtNode.setLocalContract(contract);
        if blkParams.NumberOfTableDimensions == 3
            %complicated to prove
            interpolationExtNode.setIsImported(true);
        end
    end
    
    %main_vars = outputs_dt;
    [mainCode, main_vars] = ...
        nasa_toLustre.blocks.PreLookup_To_Lustre.getMainCode(...
        inputs,wrapperNode,blkParams);

    obj.addExtenal_node(preLookUpExtNode);
    obj.addExtenal_node(wrapperNode);
    obj.setCode(mainCode);
    obj.addVariable(main_vars);

end

