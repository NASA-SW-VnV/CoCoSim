function schema = preferences_menu(callbackInfo)
    %preferences_menu Define the preferences menu function.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    schema = sl_container_schema;
    schema.label = 'Preferences';
    schema.statustip = 'Preferences';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    
    schema.childrenFcns = {...
        {@getLustreCompiler, CoCoSimPreferences}, ...
        {@getLustreBackend, CoCoSimPreferences}, ...
        {@PreferencesMenu.getCompositionalAnalysis, CoCoSimPreferences}, ...
        {@PreferencesMenu.getKind2Binary, CoCoSimPreferences}, ...
        {@PreferencesMenu.getVerificationTimeout, CoCoSimPreferences}, ...
        {@getDEDChecks, CoCoSimPreferences}...
        };
end

%% Lustre compiler
function schema = getLustreCompiler(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Lustre compiler';
    schema.statustip = 'Lustre compiler';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    callbacks = {};
    compilerName = {'NASA Compiler', 'IOWA Compiler', 'CMU Compiler'};
    for i=1:3
        callbacks{end+1} = @(x) lustreCompilerCallback(compilerName{i}, i, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreCompilerCallback(compilerName, compilerIndex, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = compilerName;
    
    if CoCoSimPreferences.lustreCompiler == compilerIndex
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    schema.callback = @(x) setCompilerOption(compilerIndex, ...
        CoCoSimPreferences, x);
end

function setCompilerOption(compilerIndex, CoCoSimPreferences, varargin)
    CoCoSimPreferences.lustreCompiler = compilerIndex;
    CoCoSimPreferences.irToLustreCompiler = compilerIndex == 2;
    PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
end

%% Lustre Backend
function schema = getLustreBackend(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Lustre Backend';
    schema.statustip = 'Lustre backend';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    callbacks = {};
    backendName = {LusBackendType.KIND2, LusBackendType.JKIND, ...
        LusBackendType.ZUSTRE};
    for i=1:numel(backendName)
        callbacks{end+1} = @(x) lustreBackendCallback(backendName{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreBackendCallback(backendName, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = backendName;
    
    if isequal(backendName, CoCoSimPreferences.lustreBackend)
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    schema.callback = @(x) setBackendOption(backendName, ...
        CoCoSimPreferences, x);
end

function setBackendOption(backendName, CoCoSimPreferences, varargin)
    CoCoSimPreferences.lustreBackend = backendName;
    PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
end

%% DED Checks
function schema = getDEDChecks(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Design Error Detection Checks';
    schema.statustip = 'Design Error Detection';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    callbacks = {};
    checksNames = {CoCoBackendType.DED_DIVBYZER,CoCoBackendType.DED_INTOVERFLOW ,...
        CoCoBackendType.DED_OUTOFBOUND, CoCoBackendType.DED_OUTMINMAX };
    for i=1:numel(checksNames)
        callbacks{end+1} = @(x) checkNameCallback(checksNames{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = checkNameCallback(checkName, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = checkName;
    
    if ismember(checkName, CoCoSimPreferences.dedChecks)
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    schema.callback = @(x) setCheckOption(checkName, ...
        CoCoSimPreferences, x);
end

function setCheckOption(checkName, CoCoSimPreferences, varargin)
    if ismember(checkName, CoCoSimPreferences.dedChecks)
        CoCoSimPreferences.dedChecks = CoCoSimPreferences.dedChecks(...
            ~strcmp(CoCoSimPreferences.dedChecks, checkName));
    else
        CoCoSimPreferences.dedChecks{end+1} = checkName;
    end
    PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
end