classdef SignalConversion_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %SignalConversion_To_Lustre translates the SignalConversion block.

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            
            codes = cell(1, numel(outputs));
            % Thanks to inlining signals as well as BusCreator and BusSelector, 
            % Signal Conversion is passing the inputs
            for i=1:numel(outputs)
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i});
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

