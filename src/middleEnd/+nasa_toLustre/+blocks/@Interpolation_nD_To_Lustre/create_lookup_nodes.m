function create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation
    
    interpolation_nDExtNode =  ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_interp_using_pre_node(...
        blkParams, inputs);

    wrapperNode = ...
        obj.get_wrapper_node(blk,interpolation_nDExtNode,blkParams);
    
    if LusBackendType.isKIND2(lus_backend) ...
            && ~(LookupType.isLookupDynamic(blkParams.lookupTableType)) ...
            && blkParams.NumberOfTableDimensions <= 3
        contractBody = Lookup_nD_To_Lustre.getContractBody(blkParams,...
            inputs,outputs);
        contract = LustreContract();
        contract.setBodyEqs(contractBody);
        interpolation_nDExtNode.setLocalContract(contract);
        if blkParams.NumberOfTableDimensions == 3
            %complicated to prove
            interpolationExtNode.setIsImported(true);
        end
    end
    
    %main_vars = outputs_dt;
    [main_call_code, main_call_vars] = ...
        obj.getMainCode(...
        blk,outputs,inputs,wrapperNode,blkParams);

    obj.addExtenal_node(interpolation_nDExtNode);
    obj.addExtenal_node(wrapperNode);
    obj.setCode(main_call_code);
    obj.addVariable(main_call_vars);

end

