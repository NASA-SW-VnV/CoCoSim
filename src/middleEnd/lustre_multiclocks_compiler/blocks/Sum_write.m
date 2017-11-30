classdef Sum_write < WriteType
    %Test_write a dummy class
    
    properties
    end
    
    methods
        
        function  write_code(obj, subsys, blk, main_sampleTime, xml_trace)
            obj.code = 'Sum block in progress';
        end
        
    end
    
end

