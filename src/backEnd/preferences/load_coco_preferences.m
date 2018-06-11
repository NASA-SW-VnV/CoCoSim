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

% save if CoCoSimPreferences is modified
if modified
    PreferencesMenu.saveCoCoSimPreferences(CoCoSimPreferences);
end
end

