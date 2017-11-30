classdef WriteType < handle
    %WriteType an interface for all write blocks classes. Any BlockType_write
    %class inherit from this class. 
    
    properties
        code = '';
        variables = {};
        external_nodes = '';
        external_libraries = {};
    end
    
    methods (Abstract)
        write_code(obj)
    end
    methods(Static)
        function name = blkTypeFormat(name)
            name = strrep(name, ' ', '');
            name = strrep(name, '-', '');
        end
        
        function b = NotHandled(type)
            blks = {'Inport', 'Outport'};
            b = ismember(type, blks);
        end
    end
    
    
    
end

