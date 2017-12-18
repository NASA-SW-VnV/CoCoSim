classdef Data
    %Data defines the data scope of a chart
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;
        scope;
        datatype;
        port;
        initial_value;
        array_size;
    end
    
    methods(Static = true)
        function obj = Data(name, scope, datatype, port, initial_value, array_size)
            obj.name = name;
            obj.scope = scope;
            obj.datatype = datatype;
            obj.port = port;
            obj.initial_value = initial_value;
            obj.array_size = array_size;
        end
        
        function d_obj = create_object(d, isevent)
            if nargin < 2
                isevent = 0;
            end
            port = d.get('Port');
            name = d.get('Name');
            scope = d.get('Scope');
            if ~isevent
                datatype = d.get('DataType');
                initial_value = d.get('Props').InitialValue;
                array_size = d.get('Props').array.size;
            else
                datatype = 'bool';
                initial_value = 'false';
                array_size = [];
            end
            
            d_obj = Data(name, scope, datatype, port, initial_value, array_size);
        end
        
    end
    
end

