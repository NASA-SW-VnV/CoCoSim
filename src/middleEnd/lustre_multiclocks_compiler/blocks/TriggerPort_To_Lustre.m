classdef TriggerPort_To_Lustre < Block_To_Lustre
    %TriggerPort is supported by SubSystem_To_Lustre. Here we add only not
    %supported options    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(varargin)
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            if strcmp(blk.TriggerType, 'function-call')
                obj.addUnsupported_options(...
                    sprintf('Option function-call is not supported in TriggerPort block %s', ...
                    blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
  
end

