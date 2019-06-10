classdef Selector_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Selector_To_Lustre
    % U and Y (inputs{1} and outputs) are inline.  In writing the Lustre
    % code, we loop over the inline outputs.  For each outputs element, we use the
    % map array ind and the ind2sub and sub2ind to seclect which element of U
    % to use.  If there is a port input, then the ind2sub and sub2ind can't be use 
    % and these tasks are done on the Lustre side.
    % This class is similiar to the Assign_To_Lustre class.  See comments
    % in the Assignment_To_Lustre.m class for definition of array ind
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, varargin)
            global CoCoSimPreferences;
            
            % share code with Assignment_To_Lustre
            isSelector = 1;
            % getBlockInputsOutputs
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            [inputs] = ...
                nasa_toLustre.blocks.Assignment_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk,isSelector);            
            
            [numOutDims, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
            
            in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
                        
            % define mapping array ind
            %outputDimsArray = in_matrix_dimension{1};   % assume full selection, will update after below function
            [isPortIndex,ind,outputDimsArray] = nasa_toLustre.blocks.Assignment_To_Lustre.defineMapInd(obj,parent,blk,inputs,in_matrix_dimension{1},isSelector);                
            
            % if index assignment is read in form index port, write mapping
            % code on Lustre side
            if isPortIndex   
                
                [codes] = getWriteCodeForPortInput(obj,blk,numOutDims,inputs,outputs,ind,outputDimsArray,in_matrix_dimension);
                
            else   % no port input.  Mapping is done in Matlab.
                
                [codes] = nasa_toLustre.blocks.Selector_To_Lustre.getWriteCodeForNonPortInput(obj,...
                    numOutDims,inputs,outputs,ind,outputDimsArray,in_matrix_dimension);
                
            end
            
           
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
            
            %% Design Error Detection Backend code:
            if isPortIndex && CoCoBackendType.isDED(coco_backend)
                blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
                
                if ismember(CoCoBackendType.DED_OUTOFBOUND, ...
                        CoCoSimPreferences.dedChecks)
                    % Add properties related to Out of bound array access.
                    U_dim = in_matrix_dimension{1}.dims;
                    port_idx = 2;
                    for i=1:numel(blk.IndexOptionArray)
                        if MatlabUtils.contains(blk.IndexOptionArray{i}, '(port)')
                            propID = sprintf('%s_OUTOFBOUND_%d',...
                                blk_name, i);
                            if strcmp(blk.IndexMode, 'Zero-based')
                                isZeroBased = true;
                            else
                                isZeroBased = false;
                            end
                            DEDUtils.OutOfBoundCheckCode(obj, parent, blk, xml_trace, ...
                                inputs{port_idx}, U_dim(i), isZeroBased, propID, i);
                            port_idx = port_idx + 1;
                        end
                    end
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            obj.unsupported_options = {};
            [numOutDims, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
            for i=1:numOutDims
                if strcmp(blk.IndexOptionArray{i}, 'Starting and ending indices (port)')
                    obj.addUnsupported_options(...
                        sprintf('Starting and ending indices (port) is not supported in block %s',...
                        HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            if numOutDims>7
                obj.addUnsupported_options(...
                    sprintf('More than 7 dimensions is not supported in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            options = obj.unsupported_options;
        end        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods
        [codes] = getWriteCodeForPortInput(obj,blk,numOutDims,inputs,...
            outputs,ind,outputDimsArray,in_matrix_dimension)        
    end
    methods(Static)        
        extNode = get_read_table_node(blk_name, U_inputs, U_LusDt)
        [codes] = getWriteCodeForNonPortInput(~, numOutDims,...
                inputs,outputs,ind,outputDimsArray,...
                in_matrix_dimension) % do not remove in_matrix_dimension parameter
                                    % It is used in eval function.        
    end        
end

