classdef SFIRPPUtils
    %SFIRPPUtils Summary of this class goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static = true)
        
        
        function new_name = adapt_root_name(name)
            new_name = regexprep(...
                nasa_toLustre.utils.SLX2LusUtils.name_format(name), '/', '_');
        end
        
        function action_Array = split_actions(actions)
            
            if ~isempty(actions) && iscell(actions)
                actions = actions(~strcmp(actions, ''));
                actions = MatlabUtils.strjoin(actions, '\n');
            end
            % clean actions from comments 
            actions = regexprep(actions, '/\*.+\*/', '');
            delim = '(;|\n)';
            action_Array = regexp(actions, delim, 'split');
            action_Array = cellfun(@(x) regexprep(x, '\s+', ''), ...
                action_Array, 'UniformOutput', false);
            action_Array = action_Array(~strcmp(action_Array,''));
        end%split_actions
       
        
        
        
    end
    
end

