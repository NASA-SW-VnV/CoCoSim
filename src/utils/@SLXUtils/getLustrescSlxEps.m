%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% Get percentage of tolerance from floiting values between lustrec and SLX
function eps = getLustrescSlxEps(model_path)
    [~, model, ~ ] = fileparts(model_path);
    if ~bdIsLoaded(model); load_system(model_path); end
    try
        eps = evalin('base', 'lustrec_slx_eps');
        return;
    catch
    end
    hws = get_param(model, 'modelworkspace') ;
    if hasVariable(hws,'lustrec_slx_eps')
        eps = getVariable(hws,'lustrec_slx_eps');
    else
        eps = 1e-2;
    end
end

