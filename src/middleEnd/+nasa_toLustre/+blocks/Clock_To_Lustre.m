classdef Clock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Clock translates the Clock block.

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            code = nasa_toLustre.lustreAst.LustreEq( outputs{1},...
                nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr()));
            obj.addCode( code);
        end
        
        function options = getUnsupportedOptions(obj,  varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

