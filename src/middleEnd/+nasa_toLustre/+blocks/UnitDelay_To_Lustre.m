classdef UnitDelay_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %UnitDelay_To_Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, ...
                main_sampleTime, varargin)
            
            InitialConditionSource = 'Dialog';
            DelayLengthSource = 'Dialog';
            DelayLength = 1;
            DelayLengthUpperLimit = 1;
            ExternalReset = 'None';
            ShowEnablePort = 'off';
            [lustre_code, delay_node_code, variables, external_libraries] = ...
                nasa_toLustre.blocks.Delay_To_Lustre.get_code( parent, blk, ...
                lus_backend, InitialConditionSource, DelayLengthSource, DelayLength,...
                DelayLengthUpperLimit, ExternalReset, ShowEnablePort, xml_trace, main_sampleTime );
            obj.addVariable(variables);
            obj.addExternal_libraries(external_libraries);
            obj.addExtenal_node(delay_node_code);
            obj.addCode(lustre_code);
           
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
    
end

