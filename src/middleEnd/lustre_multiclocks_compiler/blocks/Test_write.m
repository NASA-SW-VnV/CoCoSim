classdef Test_write < WriteType
    %Test_write a dummy class
    
    properties
    end
    
    methods
        
        function  write_code(obj, main_sampleTime, xml_trace)
            obj.code = 'test';
        end
        
    end
    
end

