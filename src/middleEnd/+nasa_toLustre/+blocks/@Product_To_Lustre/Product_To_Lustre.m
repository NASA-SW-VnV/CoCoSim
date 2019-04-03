classdef Product_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Product_To_Lustre The Product block performs multiplication or division on its
    %inputs. This block can add or subtract scalar, vector, or matrix inputs.
    %It can also collapse the elements of a signal.
    %The Sum block first converts the input data type(s) to
    %its accumulator data type, then performs the specified operations.
    %The block converts the result to its output data type using the
    %specified rounding and overflow modes.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, varargin)
            global  CoCoSimPreferences;
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            isSumBlock = false;
            [codes, outputs_dt, additionalVars, outputs] = ...
                nasa_toLustre.blocks.Sum_To_Lustre.getSumProductCodes(obj, parent, blk, ...
                OutputDataTypeStr,isSumBlock, OutputDataTypeStr, xml_trace, lus_backend);
            
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
        function options = getUnsupportedOptions(obj, parent, blk, lus_backend, varargin)
            
            % add your unsuported options list here
            if (strcmp(blk.Multiplication, 'Matrix(*)')...
                    && MatlabUtils.contains(blk.Inputs, '/') )
                for i=1:numel(blk.Inputs)
                    if isequal(blk.Inputs(i), '/')
                        if LusBackendType.isKIND2(lus_backend)
                            if blk.CompiledPortWidths.Inport(i) > 49
                                obj.addUnsupported_options(...
                                    sprintf(['Option Matrix(*) with division is not supported in block %s in inport %d. ', ...
                                    'Only less than 8x8 Matrix inversion is supported for Lustre backend KIND2.'], ...
                                    HtmlItem.addOpenCmd(blk.Origin_path), i));
                            end
                        else
                            if blk.CompiledPortWidths.Inport(i) > 16
                                obj.addUnsupported_options(...
                                    sprintf('Option Matrix(*) with division is not supported in block %s in inport %d. Only less than 5x5 Matrix inversion is supported.', ...
                                    HtmlItem.addOpenCmd(blk.Origin_path), i));
                            end
                        end
                    end
                end
            end

            b = nasa_toLustre.blocks.Sum_To_Lustre();
            obj.addUnsupported_options(b.getUnsupportedOptions( parent, blk, varargin));
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            %TODO: abstract inverse of matrix
            is_Abstracted = false;
        end
    end
    
    methods(Static)
        [codes, AdditionalVars] = matrix_multiply(obj, exp, blk, inputs, outputs, zero, LusOutputDataTypeStr, conv_format )

        [codes, product_out, addVars] = matrix_multiply_pair(m1_dim, m2_dim, ...
                input_m1, input_m2, output_m, zero, pair_number,...
                OutputDT, tmp_prefix, conv_format)
       
        [new_inputs, invertCodes, AdditionalVars] = invertInputs(obj, exp, inputs, blk, LusOutputDataTypeStr)

    end
    
end

