function create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lookup_nD
    
    interpolationExtNode = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_interp_using_pre_node(...
        blkParams,inputs);
        
    preLookUpExtNode =  ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_pre_lookup_node(...
        lus_backend,blkParams);
    
    lookupWrapperExtNode = ...
        obj.get_wrapper_node(...
        blk,blkParams,inputs,outputs,preLookUpExtNode,...
        interpolationExtNode);

    if LusBackendType.isKIND2(lus_backend) ...
            && ~(LookupType.isLookupDynamic(blkParams.lookupTableType)) ...
            && blkParams.NumberOfTableDimensions <= 3
        contractBody = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.getContractBody(...
            blkParams,inputs,outputs);
        contract = LustreContract();
        contract.setBodyEqs(contractBody);
        interpolationExtNode.setLocalContract(contract);
        if blkParams.NumberOfTableDimensions == 3
            %complicated to prove
            interpolationExtNode.setIsImported(true);
        end
    end

    [mainCode, main_vars] = ...
        obj.getMainCode(blk,outputs,inputs,lookupWrapperExtNode,blkParams);
    
    obj.addExtenal_node(preLookUpExtNode);
    obj.addExtenal_node(interpolationExtNode);
    obj.addExtenal_node(lookupWrapperExtNode);
    obj.setCode(mainCode);
    obj.addVariable(main_vars);

end

