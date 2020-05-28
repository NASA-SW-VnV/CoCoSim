%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
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
classdef Product_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Product_To_Lustre The Product block performs multiplication or division on its
    %inputs. This block can add or subtract scalar, vector, or matrix inputs.
    %It can also collapse the elements of a signal.
    %The Sum block first converts the input data type(s) to
    %its accumulator data type, then performs the specified operations.
    %The block converts the result to its output data type using the
    %specified rounding and overflow modes.
    

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            if ismember('double', blk.CompiledPortDataTypes.Inport)
                AccumDataTypeStr = 'double';
            elseif ismember('single', blk.CompiledPortDataTypes.Inport)
                AccumDataTypeStr = 'single';
            elseif length(unique(blk.CompiledPortDataTypes.Inport)) == 1
                AccumDataTypeStr = blk.CompiledPortDataTypes.Inport{1};
                if strcmp(AccumDataTypeStr, 'boolean')
                    AccumDataTypeStr = 'uint8';
                end
            elseif all(coco_nasa_utils.MatlabUtils.contains(blk.CompiledPortDataTypes.Inport, 'int'))
                AccumDataTypeStr = 'int32';
            else
                AccumDataTypeStr = 'double';
            end
            isSumBlock = false;
            [codes, outputs_dt, additionalVars, outputs] = ...
                nasa_toLustre.blocks.Sum_To_Lustre.getSumProductCodes(obj, parent, blk, ...
                OutputDataTypeStr, isSumBlock,  AccumDataTypeStr, xml_trace, lus_backend, main_sampleTime);
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
            obj.addVariable(additionalVars);
            
            %% Design Error Detection Backend code:
            if coco_nasa_utils.CoCoBackendType.isDED(coco_backend)
                if ismember(coco_nasa_utils.CoCoBackendType.DED_OUTMINMAX, ...
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
                    && coco_nasa_utils.MatlabUtils.contains(blk.Inputs, '/') )
                for i=1:numel(blk.Inputs)
                    if strcmp(blk.Inputs(i), '/')
                        if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
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
        [codes, AdditionalVars] = matrix_multiply(obj, exp, blk, inputs, outputs, zero, LusOutputDataTypeStr, conv_format, operandsDT )

        [codes, product_out, addVars] = matrix_multiply_pair(m1_dim, m2_dim, ...
                input_m1, input_m2, output_m, zero, pair_number,...
                OutputDT, tmp_prefix, conv_format, operandsDT)
       
        [new_inputs, invertCodes, AdditionalVars] = invertInputs(obj, exp, inputs, blk, LusOutputDataTypeStr)

    end
    
end

