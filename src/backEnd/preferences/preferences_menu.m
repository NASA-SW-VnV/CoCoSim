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

CoCoSimPreferences = load_coco_preferences();

schema.childrenFcns = {...
    {@getLustreCompiler, CoCoSimPreferences}, ...
    {@PreferencesMenu.getCompositionalAnalysis, CoCoSimPreferences}, ...
    {@PreferencesMenu.getKind2Binary, CoCoSimPreferences}, ...
    {@PreferencesMenu.getVerificationTimeout, CoCoSimPreferences}, ...
    };
end

%%
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

