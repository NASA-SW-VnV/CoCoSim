classdef CoCoSimPreferences < handle
    %CoCoSimPreferences Lists default values of CoCoSim preferences.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        % CoCoSim preferences default values
        preferencesPath = ''; % where preferences will be stored
        modelChecker = 'Kind2';
        irToLustreCompiler = false; %only used by cocosim IOWA
        compositionalAnalysis = true; %Kind2 compositionalAnalysis
        kind2Binary = 'Local';% possible values are {'Kind2 web service', 'Docker', 'Local'}
        lustrecBinary = 'Local';% possible values are {'Docker', 'Local'}
        verificationTimeout = 1200; % In seconds
        lustreCompiler = 'NASA';% possible values are {'NASA', 'IOWA'}
        lustreBackend = LusBackendType.KIND2; % see LusBackendType for possible values
        dedChecks = {CoCoBackendType.DED_OUTMINMAX}; 
        %{CoCoBackendType.DED_DIVBYZER,CoCoBackendType.DED_INTOVERFLOW ,...
         %   CoCoBackendType.DED_OUTOFBOUND, CoCoBackendType.DED_OUTMINMAX }; % check CoCoBackendType for Design Error Detection values
        DED_OUTOFBOUND = 'Out of Bound Array Access';
        
        % nasa_toLustre compiler: force typecasting of int to int8, int16, ...
        forceTypeCastingOfInt = true;
        forceCodeGen = false;
        skip_sf_actions_check = false;
        skip_optim = false;
        skip_unsupportedblocks = false;
        skip_defected_pp = true;
        skip_pp = false;
        use_more_precise_abstraction = false;
        %gen_pp_verif = false;
    end
    
    methods(Static)
        function preferencesFile = getPreferencesMatPath()
            fpath = fileparts(mfilename('fullpath'));
            preferencesFile = fullfile(fpath, 'preferences.mat');
        end
        
        function [ CoCoSimPreferences, modified ] = load()
            modified = false;
            preferencesPath = cocosim_menu.CoCoSimPreferences.getPreferencesMatPath();
            if exist(preferencesPath, 'file') == 2
                load(preferencesPath, 'CoCoSimPreferences');
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
                CoCoSimPreferences.preferencesPath = preferencesPath;
                save(preferencesPath, 'CoCoSimPreferences');
            end
            warning('on', 'MATLAB:structOnObject')
        end
        
        function save(CoCoSimPreferences)% Ignore warning: the parameter is used by save function
            if isfield(CoCoSimPreferences, 'preferencesPath')
                save(CoCoSimPreferences.preferencesPath, 'CoCoSimPreferences');
            else
                preferencesPath = cocosim_menu.CoCoSimPreferences.getPreferencesMatPath();
                save(preferencesPath, 'CoCoSimPreferences');
            end
        end
        
        function deletePreferences(CoCoSimPreferences)
            if isfield(CoCoSimPreferences, 'preferencesPath')
                delete(CoCoSimPreferences.preferencesPath);
            else
                preferencesFile = cocosim_menu.CoCoSimPreferences.getPreferencesMatPath();
                delete(preferencesFile);
            end
        end
        function msg = getChangeModelCheckerMsg()
            msg = 'To change the default model checker go to "tools -> CoCoSim -> Preferences -> Lustre Verification Backend".';
        end
    end
end
