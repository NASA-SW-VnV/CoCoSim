classdef ZeroOrderHold_To_Lustre < Block_To_Lustre
    %ZeroOrderHold_To_Lustre translates the ZeroOrderHold block.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, main_sampleTime, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            %% calculated by rateTransition_ir_pp
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            outTs = OutportCompiledSampleTime(1);
            outTsOffset = OutportCompiledSampleTime(2);
            
            
            
            %%
            codes = {};
            
            clockName = SLX2LusUtils.clockName(outTs/main_sampleTime(1), outTsOffset/main_sampleTime(1));
            for i=1:numel(outputs)
                codes{i} = sprintf('%s = %s when %s;\n\t', outputs{i}, inputs{i}, clockName);
            end
            
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

