classdef Sum_write < Block_To_Lustre
    %Sum_write Translate Sum block to Lustre.
    
    properties
    end
    
    methods
        
        function  write_code(obj, subsys, blk, main_sampleTime, xml_trace)
            obj.code = 'Sum block in progress';
        end
        
        function getUnsupportedOptions(obj, varargin)
           obj.unsupported_options = {};  
        end
    end
    
end

