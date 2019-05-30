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
            [outputs, outputs_dt] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, ...
                blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            blkParams = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.getInitBlkParams(...
                blk,lus_backend);
            blkParams = obj.readBlkParams(parent,blk,blkParams);
            
            [inputs] = obj.getInputs(parent, blk, blkParams);
            
            
            
            obj.addExternal_libraries({'LustMathLib_abs_real'});
            wrapperNode = obj.create_lookup_nodes(blk,lus_backend,blkParams,outputs,inputs);
            
            mainCode = obj.getMainCode(blk,outputs,inputs,...
                wrapperNode,blkParams);
            obj.addCode(mainCode);
        end
        
        %%
        function options = getUnsupportedOptions(obj,~, blk, varargin)
            if strcmp(blk.InterpMethod,'Linear') ...
                    && ~(strcmp(blk.IntermediateResultsDataTypeStr,'Inherit: Inherit via internal rule')...
                    ||strcmp(blk.IntermediateResultsDataTypeStr,'single') ...
                    ||strcmp(blk.IntermediateResultsDataTypeStr,'double'))
                obj.addUnsupported_options(sprintf(...
                    'IntermediateResultsDataTypeStr in block "%s" should be double or single',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        [inputs] = getInputs(obj, parent, blk, blkParams)
        
        blkParams = readBlkParams(obj,parent,blk,blkParams)
        
        wrapperNode = create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
        
        extNode =  get_wrapper_node(obj,interpolation_nDExtNode,blkParams)
        
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
        
        [body, vars] = ...
            addDirectLookupNodeCode_Interpolation_nD(...
            blkParams,bound_nodes_for_dim_name,...
            Ast_dimJump,fraction_name,k_name)
        
        extNode =  get_wrapper_interp_ext_node(...
            blk,outputs,interpolation_nDExtNode,blkParams)
        
        [body, vars, node_header, bounding_nodes] =  ...
            get_wrapper_common_code(blk,blkParams)
        
        extNode = get_adjusted_table_node(...
            blkParams,node_header,blk_inputs);
        
        function dim = reduceDim(dim)
            if dim(1) == 1 && length(dim) > 1
                dim = dim(2:end);
            end
            if dim(end) == 1 && length(dim) > 1
                dim = dim(1:end-1);
            end
        end
    end
    
end

