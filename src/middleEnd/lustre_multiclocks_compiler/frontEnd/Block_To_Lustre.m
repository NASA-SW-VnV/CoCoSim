classdef Block_To_Lustre < handle
    %Block_To_Lustre an interface for all write blocks classes. Any BlockType_write
    %class inherit from this class. 
    
    properties
        code = '';
        variables = {};
        external_nodes = '';
        external_libraries = {};
        unsupported_options = {};
    end
    
    methods (Abstract)
        write_code(obj)
        getUnsupportedOptions(obj)
    end
    methods(Static)
        function name = blkTypeFormat(name)
            name = strrep(name, ' ', '');
            name = strrep(name, '-', '');
        end
        
        function b = NotHandled(type)
            % add blocks that will not be handled.
            blks = {'Inport'};
            b = ismember(type, blks);
        end
    end
    
    
    
end

