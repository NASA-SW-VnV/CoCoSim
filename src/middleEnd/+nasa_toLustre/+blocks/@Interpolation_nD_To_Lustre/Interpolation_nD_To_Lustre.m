%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Interpolation_nD_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre ...
        & nasa_toLustre.blocks.BaseLookup
    % Interpolation_nD_To_Lustre
%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, ...
                blk, [], xml_trace, main_sampleTime);
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
            
            %% Design Error Detection Backend code:
            if coco_nasa_utils.CoCoBackendType.isDED(coco_backend)
                if ismember(coco_nasa_utils.CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    outputDataType = blk.CompiledPortDataTypes.Outport{1};
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
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

