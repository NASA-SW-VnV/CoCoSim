classdef TriggerPort_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %TriggerPort is supported by SubSystem_To_Lustre. Here we add only not
    %supported options    

    properties
    end
    
    methods
        
        function  write_code(varargin)
        end
        %%
        function options = getUnsupportedOptions(obj, ~, ~, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
  
end

