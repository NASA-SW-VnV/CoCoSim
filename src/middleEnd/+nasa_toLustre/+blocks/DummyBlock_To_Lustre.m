classdef DummyBlock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % This is a dummy class.

    
    properties
        isBooleanExpr = 0;
    end
    
    methods
        
        function  write_code(varargin)            
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

