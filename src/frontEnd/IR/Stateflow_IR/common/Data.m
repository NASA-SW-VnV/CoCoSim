classdef Data
    %Data defines the data scope of a chart
    properties
        name;
        scope;
        datatype;
        initial_value;
    end
    
    methods(Static = true)
        function obj = Data(name, scope, datatype, initial_value)
            obj.name = name;
            obj.scope = scope;
            obj.datatype = datatype;
            obj.initial_value = initial_value;
        end
        
        function d_obj = create_object(d, isevent)
            if nargin < 2
                isevent = 0;
            end
            name = d.get('Name');
            scope = d.get('Scope');
            if ~isevent
                datatype = d.get('DataType');
                initial_value = d.get('Props').InitialValue;
            else
                datatype = 'bool';
                initial_value = 'false';
            end
            
            d_obj = Data(name, scope, datatype, initial_value);
        end
        
    end
    
end

