function wrapperNode = create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PreLookup
    
    preLookUpExtNode =  ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_pre_lookup_node(...
        lus_backend,blkParams,inputs);
    
    wrapperNode = ...
        obj.get_wrapper_node(...
        blk,inputs,outputs,preLookUpExtNode,blkParams);
    
    nasa_toLustre.blocks.Lookup_nD_To_Lustre.com_create_nodes_code(obj,...
        lus_backend,blkParams,inputs,outputs,preLookUpExtNode,...
        {},wrapperNode,blk);    

end

