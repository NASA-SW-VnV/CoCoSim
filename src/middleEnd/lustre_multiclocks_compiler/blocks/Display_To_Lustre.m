classdef Display_To_Lustre < Block_To_Lustre
    %Display block does nothing
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            obj.setCode('');
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
           options = obj.unsupported_options;
           
        end
    end
    
end

