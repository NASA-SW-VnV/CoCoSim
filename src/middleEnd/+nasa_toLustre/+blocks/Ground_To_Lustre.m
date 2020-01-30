classdef Ground_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Ground_To_Lustre

    
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            lus_outputDataType =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            
            if strcmp(lus_outputDataType, 'bool')
                v = nasa_toLustre.lustreAst.BoolExpr('false');
            elseif strcmp(lus_outputDataType, 'int')
                v = nasa_toLustre.lustreAst.IntExpr('0');
            else
                v = nasa_toLustre.lustreAst.RealExpr('0.0');
            end
            
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, v);
            end
            
            obj.addCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
    
end

