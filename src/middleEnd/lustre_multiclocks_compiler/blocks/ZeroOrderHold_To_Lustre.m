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
            % calculated by rateTransition_ir_pp
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            outTs = OutportCompiledSampleTime(1);
            outTsOffset = OutportCompiledSampleTime(2);
                        
            clockName = SLX2LusUtils.clockName(outTs/main_sampleTime(1), outTsOffset/main_sampleTime(1));
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                codes{i} = LustreEq(outputs{i}, ...
                    BinaryExpr(BinaryExpr.WHEN, ...
                                inputs{i}, ...
                                VarIdExpr(clockName)));
            end
            
            obj.setCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj,~, blk, ~, backend, varargin)
            if BackendType.isKIND2(backend)
                obj.addUnsupported_options(...
                    sprintf('multi-clocks in block "%s" is currently not supported by KIND2.', blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

