classdef Width_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Width_To_Lustre

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            
            
            codes =  cell(1, numel(outputs));
            
            
            slx_dt = blk.CompiledPortDataTypes.Outport{1};
            lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
            width = blk.CompiledPortWidths.Inport(1);
            codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs{1}, ...
                nasa_toLustre.utils.SLX2LusUtils.num2LusExp(width, lus_dt, slx_dt));
            
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

