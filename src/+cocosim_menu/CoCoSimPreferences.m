%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef CoCoSimPreferences < handle
    %CoCoSimPreferences Lists default values of CoCoSim preferences.

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
        abstract_unsupported_blocks = true;
        skip_defected_pp = true;
        skip_pp = false;
        use_more_precise_abstraction = false;
        %gen_pp_verif = false;
        
        cocosim_verbose = 0;
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
            if isfield(CoCoSimPreferences, 'preferencesPath')...
                    && exist(CoCoSimPreferences.preferencesPath, 'file') 
                save(CoCoSimPreferences.preferencesPath, 'CoCoSimPreferences');
            else
                preferencesPath = cocosim_menu.CoCoSimPreferences.getPreferencesMatPath();
                save(preferencesPath, 'CoCoSimPreferences');
            end
        end
        
        function deletePreferences(CoCoSimPreferences)
            if isfield(CoCoSimPreferences, 'preferencesPath') ...
                    && exist(CoCoSimPreferences.preferencesPath, 'file') 
                delete(CoCoSimPreferences.preferencesPath);
            else
                preferencesFile = cocosim_menu.CoCoSimPreferences.getPreferencesMatPath();
                if exist(preferencesFile, 'file') 
                    delete(preferencesFile);
                end
            end
        end
        function msg = getChangeModelCheckerMsg()
            msg = 'To change the default model checker go to "tools -> CoCoSim -> Preferences -> Lustre Verification Backend".';
        end
    end
end
