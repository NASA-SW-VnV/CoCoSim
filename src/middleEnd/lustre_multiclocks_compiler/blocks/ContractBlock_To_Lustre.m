classdef ContractBlock_To_Lustre < Block_To_Lustre
    % ContractBlock_To_Lustre translates contract observer as contract in
    % kind2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            % Contracts Subsystems willl be ignored as they will be
            % imported in the node definition of the associate Simulink
            % Subsystem.
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
           options = obj.unsupported_options;
           
        end
    end
    
end

