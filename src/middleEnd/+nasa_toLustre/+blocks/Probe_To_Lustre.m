classdef Probe_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Probe_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
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

