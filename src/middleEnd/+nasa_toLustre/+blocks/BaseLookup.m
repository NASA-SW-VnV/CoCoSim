classdef BaseLookup < handle
    % base class for Lookup_nD_To_Lustre, LookupTableDynamic_To_Lustre,
    % PreLookup_To_Lustre and Interpolation_nD_To_Lustre
    
    properties
        
    end
    
    methods (Abstract)
        blkParams = readBlkParams(obj,parent,blk,blkParams)
        
        create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
                
        extNode =  get_wrapper_node(obj,blk,blkParams,inputs,...
            outputs,preLookUpExtNode,interpolationExtNode)
        
    end
end

