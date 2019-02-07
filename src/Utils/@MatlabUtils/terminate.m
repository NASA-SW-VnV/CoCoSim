
function terminate(modelName)
    if nargin < 1 || isempty(modelName)
        modelName = gcs;
    end
    evalin('base', sprintf('%s([], [], [], ''term'')', modelName));
end
        
