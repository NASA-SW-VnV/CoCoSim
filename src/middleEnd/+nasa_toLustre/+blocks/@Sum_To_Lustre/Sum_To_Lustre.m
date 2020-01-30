classdef Sum_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Sum_To_Lustre The Sum block performs addition or subtraction on its
    %inputs. This block can add or subtract scalar, vector, or matrix inputs.
    %It can also collapse the elements of a signal.
    %The Sum block first converts the input data type(s) to
    %its accumulator data type, then performs the specified operations.
    %The block converts the result to its output data type using the
    %specified rounding and overflow modes.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            AccumDataTypeStr = blk.AccumDataTypeStr;
            if strcmp(AccumDataTypeStr, 'Inherit: Inherit via internal rule')
                AccumDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            elseif strcmp(AccumDataTypeStr, 'Inherit: Same as first input')
                AccumDataTypeStr = blk.CompiledPortDataTypes.Inport{1};
            end
            
           
            isSumBlock = true;
            [codes, outputs_dt, additionalVars, outputs] = ...
                nasa_toLustre.blocks.Sum_To_Lustre.getSumProductCodes(obj, parent, blk, ...
                OutputDataTypeStr,isSumBlock,AccumDataTypeStr, xml_trace, lus_backend, main_sampleTime);
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
            obj.addVariable(additionalVars);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(OutputDataTypeStr);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, ~,  blk, varargin)
            % if there is one input and the output dimension is > 7
            if numel(blk.CompiledPortWidths.Inport) == 1 ...
                    &&  numel(blk.CompiledPortDimensions.Outport) > 7
                obj.addUnsupported_options(...
                    sprintf('Dimension %s in block %s is not supported.',...
                    mat2str(blk.CompiledPortDimensions.Inport), HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    methods(Static)
        [codes, outputs_dt, AdditionalVars, outputs] = getSumProductCodes(...
                obj, parent, blk, OutputDataTypeStr,isSumBlock, ...
                AccumDataTypeStr, xml_trace, lus_backend, main_sampleTime)

        inputs = createBlkInputs(obj, parent, blk, widths, ...
                AccumDataTypeStr, isSumBlock)

        [codes] = elementWiseSumProduct(exp, inputs, outputs, ...
                widths, initCode, conv_format, int_divFun, operandsDT)

        [codes] = oneInputSumProduct(parent, blk, outputs, inputs, ...
                widths, exp, initCode,isSumBlock, conv_format)
        %%
        [numelCollapseDim, delta, collapseDims] = ...
                collapseMatrix(in_matrix_dimension, CollapseDim)

    end
    
end

