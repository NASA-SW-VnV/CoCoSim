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
        {@getKind2Options, CoCoSimPreferences}, ...
        {@PreferencesMenu.getVerificationTimeout, CoCoSimPreferences}, ...
        {@getDEDChecks, CoCoSimPreferences}, ...
        @resetSettings ...
        };
end

%% Lustre compiler
function schema = getLustreCompiler(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Simulink To Lustre compiler';
    schema.statustip = 'Lustre compiler';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    compilerNames = {'NASA Compiler', 'IOWA Compiler'};
    callbacks = cell(1, length(compilerNames));
    for i=1:length(compilerNames)
        callbacks{i} = @(x) lustreCompilerCallback(compilerNames{i}, i, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreCompilerCallback(compilerName, compilerIndex, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = compilerName;
    compilerNameValues = {'NASA', 'IOWA'};
    if isequal(CoCoSimPreferences.lustreCompiler, compilerNameValues{compilerIndex})
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    schema.callback = @(x) setCompilerOption(compilerNameValues{compilerIndex}, ...
        CoCoSimPreferences, x);
end

function setCompilerOption(compilerNameValue, CoCoSimPreferences, varargin)
    CoCoSimPreferences.lustreCompiler = compilerNameValue;
    CoCoSimPreferences.irToLustreCompiler = isequal(compilerNameValue, 'IOWA');
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Lustre Backend
function schema = getLustreBackend(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Verification Backend';
    schema.statustip = 'Lustre backend';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    
    backendNames = {LusBackendType.KIND2, LusBackendType.JKIND, ...
        LusBackendType.ZUSTRE};
    callbacks = cell(1, length(backendNames));
    for i=1:length(backendNames)
        callbacks{i} = @(x) lustreBackendCallback(backendNames{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreBackendCallback(backendName, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = backendName;
    if ~strcmp(backendName, LusBackendType.KIND2)
        schema.state = 'Disabled';
        schema.label = strcat(backendName, ' (Currently unsupported)');
    else
        schema.label = backendName;
    end
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
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Kind2 options
function schema = getKind2Options(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Kind2 Preferences';
    schema.statustip = 'Kind2 Preferences';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = callbackInfo.userdata;
    
    schema.childrenFcns = {...
        {@PreferencesMenu.getCompositionalAnalysis, CoCoSimPreferences}, ...
        {@PreferencesMenu.getKind2Binary, CoCoSimPreferences}
        };
end
%% DED Checks
function schema = getDEDChecks(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Design Error Detection Checks';
    schema.statustip = 'Design Error Detection';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    checksNames = {CoCoBackendType.DED_DIVBYZER,CoCoBackendType.DED_INTOVERFLOW ,...
        CoCoBackendType.DED_OUTOFBOUND, CoCoBackendType.DED_OUTMINMAX };
    callbacks = cell(1, length(checksNames));
    for i=1:length(checksNames)
        callbacks{i} = @(x) checkNameCallback(checksNames{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = checkNameCallback(checkName, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    if ~strcmp(checkName, CoCoBackendType.DED_OUTMINMAX)
        schema.state = 'Disabled';
        schema.label = strcat(checkName, ' (Work in progress)');
    else
        schema.label = checkName;
    end
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
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Reset Settings
function schema = resetSettings(varargin)
    schema = sl_action_schema;
    schema.label = 'Reset preferences';
    schema.statustip = 'Reset preferences';
    schema.autoDisableWhen = 'Busy';
    schema.callback = @(x) cocosim_menu.CoCoSimPreferences.delete();
end