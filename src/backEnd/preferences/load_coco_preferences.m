function [ CoCoSimPreferences ] = load_coco_preferences(  )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Loading the old preferences
    [ CoCoSimPreferences ] = loadCoCoSimPreferences();
    
    modified = false;
    
    % check if the lustreCompiler is defined
    if ~ isfield(CoCoSimPreferences,'lustreCompiler')
        CoCoSimPreferences.lustreCompiler = 1;
        modified = true;
    end
    
    % check if the lustreCompiler is defined
    if ~ isfield(CoCoSimPreferences,'lustreBackend')
        CoCoSimPreferences.lustreBackend = LusBackendType.KIND2;
        modified = true;
    end
    
    % check if DED checks are defined
    if ~ isfield(CoCoSimPreferences, 'dedChecks')
        CoCoSimPreferences.dedChecks = {CoCoBackendType.DED_DIVBYZER,CoCoBackendType.DED_INTOVERFLOW ,...
            CoCoBackendType.DED_OUTOFBOUND, CoCoBackendType.DED_OUTMINMAX };
        modified = true;
    end
    
    % check if verificationTimeout is defined
    if ~ isfield(CoCoSimPreferences,'verificationTimeout')
        CoCoSimPreferences.verificationTimeout = 1200; %1200 seconds = 20 minutes
        modified = true;
    end
    
    % save if CoCoSimPreferences is modified
    if modified
        PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
    end
end

