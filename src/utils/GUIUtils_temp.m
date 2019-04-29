%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
classdef GUIUtils
    %GUIUtils Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        %% Update CoCoSim GUI
        function update_status(status)
            try
                h = evalin('base','cocosim_status_handle');
                h.String = status;
                drawnow limitrate
            catch
                assignin('base','cocosim_status',status)
            end
        end
        
      
        
      
    end
    
end

