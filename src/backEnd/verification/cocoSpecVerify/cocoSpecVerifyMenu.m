function schema = cocoSpecVerifyMenu(callbackInfo)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

    schema = sl_container_schema;
    schema.label = 'Compositional Verification';
    schema.statustip = 'Verify the current model with CoCoSim';
    schema.autoDisableWhen = 'Busy';

    schema.childrenFcns = {@getKind};
end
function schema = getKind(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Kind2';
    schema.callback = @kindCallback;
end

function kindCallback(callbackInfo)
    assignin('base', 'SOLVER', 'K');
    [ CoCoSimPreferences ] = loadCoCoSimPreferences();
    CoCoSimPreferences.compositionalAnalysis = true;
    PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
    VerificationMenu.runCoCoSim;
end