function [desc] = get_obs_description()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    desc = sprintf('Set an observer for the system.\n');
    desc = [desc sprintf('The annotation type parameter sets the type of observer:\n')];
    desc = [desc sprintf('- requires : pre-condition\n')];
    desc = [desc sprintf('- ensures : post-condition\n')];
    desc = [desc sprintf('- assert : an assertion\n')];
    desc = [desc sprintf('- observer : the observer computes a special type of properties')];

end
