
%% Get percentage of tolerance from floiting values between lustrec and SLX
function eps = getLustrescSlxEps(model_path)
    [~, model, ~ ] = fileparts(model_path);
    if ~bdIsLoaded(model); load_system(model_path); end
    hws = get_param(model, 'modelworkspace') ;
    if hasVariable(hws,'lustrec_slx_eps')
        eps = getVariable(hws,'lustrec_slx_eps');
    else
        eps = 1e-4;
    end
end

