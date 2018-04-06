classdef block_diagram_To_Lustre < Block_To_Lustre
    %block_diagram_To_Lustre Here we add only not supported options in a block diagram
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
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            if Subsystem_To_Lustre.hasEnablePort(blk) ...
                    || Subsystem_To_Lustre.hasTriggerPort(blk) ...
                    || Subsystem_To_Lustre.hasResetPort(blk)
                obj.addUnsupported_options(...
                    sprintf('Block diagram "%s" with Enable/Trigger/Reset port in root level is not supported.', ...
                    blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
    
end

