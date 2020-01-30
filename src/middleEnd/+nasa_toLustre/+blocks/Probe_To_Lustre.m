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
classdef Probe_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Probe_To_Lustre

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            
            
            codes =  cell(1, numel(outputs));
            % blk_out_idx refers to port number of outpot
            blk_out_idx = 1;
            % refers to current idx of "outputs" variable
            outputs_idx = 1;
            if strcmp(blk.ProbeWidth, 'on')
                slx_dt = blk.CompiledPortDataTypes.Outport{blk_out_idx};
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
                width = blk.CompiledPortWidths.Inport(1);
                codes{outputs_idx} = nasa_toLustre.lustreAst.LustreEq(outputs{outputs_idx}, ...
                    nasa_toLustre.utils.SLX2LusUtils.num2LusExp(width, lus_dt, slx_dt));
                blk_out_idx = blk_out_idx + 1;
                outputs_idx = outputs_idx + 1;
            end
            
            if strcmp(blk.ProbeSampleTime, 'on')
                slx_dt = blk.CompiledPortDataTypes.Outport{blk_out_idx};
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
                % Sample Time is Inherited from driving block
                sampleTime = blk.CompiledSampleTime;
                codes{outputs_idx} = nasa_toLustre.lustreAst.LustreEq(outputs{outputs_idx}, ...
                    nasa_toLustre.utils.SLX2LusUtils.num2LusExp(sampleTime(1), lus_dt, slx_dt));
                outputs_idx = outputs_idx + 1;
                codes{outputs_idx} = nasa_toLustre.lustreAst.LustreEq(outputs{outputs_idx}, ...
                    nasa_toLustre.utils.SLX2LusUtils.num2LusExp(sampleTime(2), lus_dt, slx_dt));
                outputs_idx = outputs_idx + 1;
                blk_out_idx = blk_out_idx + 1;
            end
            
            if strcmp(blk.ProbeComplexSignal, 'on')
                slx_dt = blk.CompiledPortDataTypes.Outport{blk_out_idx};
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
                complexSignal = blk.CompiledPortComplexSignals.Inport(1);
                codes{outputs_idx} = nasa_toLustre.lustreAst.LustreEq(outputs{outputs_idx}, ...
                    nasa_toLustre.utils.SLX2LusUtils.num2LusExp(complexSignal, lus_dt, slx_dt));
                blk_out_idx = blk_out_idx + 1;
                outputs_idx = outputs_idx + 1;
            end
            
            
            if strcmp(blk.ProbeSignalDimensions, 'on')
                slx_dt = blk.CompiledPortDataTypes.Outport{blk_out_idx};
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
                inport_dimensions = blk.CompiledPortDimensions.Inport;
                in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(inport_dimensions);
                dims = in_matrix_dimension{1}.dims;
                for d=dims
                    codes{outputs_idx} = nasa_toLustre.lustreAst.LustreEq(outputs{outputs_idx}, ...
                        nasa_toLustre.utils.SLX2LusUtils.num2LusExp(d, lus_dt, slx_dt));
                    outputs_idx = outputs_idx + 1;
                end                
            end
            obj.addCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
    
end

