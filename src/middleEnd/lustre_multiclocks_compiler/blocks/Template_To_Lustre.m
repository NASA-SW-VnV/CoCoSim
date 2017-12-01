classdef Template_To_Lustre < Block_To_Lustre
    %Test_write a dummy class
    
    properties
    end
    
    methods
        
        function  write_code(obj, varargin)
            obj.code = 'You code here';
        end
        
        function getUnsupportedOptions(obj, varargin)
           obj.unsupported_options = {'your unsuported options list here'};  
        end
    end
    
end

