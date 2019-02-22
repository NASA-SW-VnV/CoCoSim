classdef CoCoSimPreferences < handle
    %CoCoSimPreferences Lists default values of CoCoSim preferences.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        % CoCoSim preferences default values
        
        modelChecker = 'Kind2';
        irToLustreCompiler = false; %only used by cocosim IOWA
        compositionalAnalysis = true; %Kind2 compositionalAnalysis
        kind2Binary = 'Local';% possible values are {'Kind2 web service', 'Local'}
        verificationTimeout = 1200; % In seconds
        lustreCompiler = 'NASA';% possible values are {'NASA', 'IOWA'}
        lustreBackend = LusBackendType.KIND2; % see LusBackendType for possible values
        dedChecks = {CoCoBackendType.DED_DIVBYZER,CoCoBackendType.DED_INTOVERFLOW ,...
            CoCoBackendType.DED_OUTOFBOUND, CoCoBackendType.DED_OUTMINMAX }; % check CoCoBackendType for Design Error Detection values
        DED_OUTOFBOUND = 'Out of Bound Array Access';
    end
    
    methods(Static)
        function [ CoCoSimPreferences, modified ] = load()
            modified = false;
            fpath = fileparts(mfilename('fullpath'));
            preferencesFile = fullfile(fpath, 'preferences.mat');
            if exist(preferencesFile, 'file') == 2
                
                load(preferencesFile, 'CoCoSimPreferences');
            end
            warning('off', 'MATLAB:structOnObject')
            if ~exist('CoCoSimPreferences', 'var')
                c = cocosim_menu.CoCoSimPreferences();
                CoCoSimPreferences = struct(c);
                modified = true;
                
            else
                c = cocosim_menu.CoCoSimPreferences();
                c_fields = fieldnames(struct(c));
                cocoPrefs_fields = fieldnames(CoCoSimPreferences);% Ignore warning
                if length(c_fields) ~= length(cocoPrefs_fields) ...
                        || ~isequal(sort(cocoPrefs_fields), sort(c_fields))
                    fields_diff = c_fields(cellfun(@(x) ~ismember(x, cocoPrefs_fields), c_fields));
                    for i=1:length(fields_diff)
                        CoCoSimPreferences.(fields_diff{i}) = c.(fields_diff{i});
                    end
                    modified = true;
                end
                
            end
            % store the last version
            if modified
                save(preferencesFile, 'CoCoSimPreferences');
            end
            warning('on', 'MATLAB:structOnObject')
        end
    end
end
