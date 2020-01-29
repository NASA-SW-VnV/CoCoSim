function already_pp = isAlreadyPP(model_path)
    %% detecte if it is already pre-processed
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    [~, model, ~ ] = fileparts(model_path);
    if ~bdIsLoaded(model); load_system(model_path); end
    hws = get_param(model, 'modelworkspace') ;
    already_pp = hasVariable(hws,'already_pp') && getVariable(hws,'already_pp') == 1;
end

