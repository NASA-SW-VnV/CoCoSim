classdef SF_To_LustreNode
    %SF_To_LustreNode translates a Stateflow chart to Lustre node
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        [main_node, external_nodes, external_libraries ] = ...
                chart2node(parent,  chart,  main_sampleTime, lus_backend, xml_trace)

        %% Get unique short name
        unique_name = getUniqueName(object, id)
        
        %% special Var Names
        v = virtualVarStr()

        v = isInnerStr()

        %% Order states, transitions ...
        ordered = orderObjects(objects, fieldName)

        %% change events to data
        data = eventsToData(event_s)  %TODO "events" cause eror here (why?).. changing from events to event_s

        vars = getDataVars(d_list)

        names = getDataName(d)

        SF_DATA_MAP = addArrayData(SF_DATA_MAP, d_list)

    end
end