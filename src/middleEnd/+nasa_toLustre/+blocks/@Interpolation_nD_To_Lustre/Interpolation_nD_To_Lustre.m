classdef Interpolation_nD_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre ...
        & nasa_toLustre.blocks.BaseLookup
    % Interpolation_nD_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
  
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
            
            blkParams = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.getInitBlkParams(blk);            
            blkParams = obj.readBlkParams(parent,blk,blkParams);    
            
            [outputs, ~] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, ...
                blk, [], xml_trace);
            
            % get block inputs
            inputs =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);

%                 nasa_toLustre.blocks.Lookup_nD_To_Lustre.getBlockInputsNames_convInType2AccType(...
%                 obj, parent,...
%                 blk);
            
            obj.addExternal_libraries({'LustMathLib_abs_real'});
            obj.create_lookup_nodes(blk,lus_backend,blkParams,outputs,inputs);

        end
        
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
               
        blkParams = readBlkParams(obj,parent,blk,blkParams)
        
        create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
        
        extNode =  get_wrapper_node(obj,blk,interpolation_nDExtNode,blkParams)
        
        extNode =  get_wrapper_retrieval_node(obj,blk,...
            blkParams,inputs,outputs,preLookUpExtNode,interpolationExtNode)
        
        [mainCode, main_vars] = getMainCode(obj,blk,outputs,...
            inputs,interpolation_nDWrapperExtNode,blkParams)         
        
        
        
        
    end
    
    methods(Static)
        
        %         blkParams = ...
        %             readBlkParams_PreLookup(parent,blk,inputs,blkParams)
        %
        %         [body, vars] = addFinalCode_PreLookup(...
        %         outputs,inputs,indexDataType,blk_name,blkParams,N_shape_node,...
        %         lusInport_dt,index_node, lus_backend)
        
        extNode =  get_wrapper_interp_ext_node(...
            blk,outputs,interpolation_nDExtNode,blkParams)
        
        [body, vars, node_header, bounding_nodes] =  ...
            get_wrapper_common_code(blk,blkParams)
        
        extNode = get_adjusted_table_node(...
            blkParams,node_header,blk_inputs);
    end
    
end

