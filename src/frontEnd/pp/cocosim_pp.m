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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new_file_path, failed] = cocosim_pp(model_path, varargin)
    % COCOSIM_PP pre-process complexe blocks in Simulink model into basic ones. 
    % This is a generic function that use pp_config as a configuration file that decides
    % which libraries to use and in which order to call the blocks functions.
    % See pp_config for more details.
    % Inputs:
    % file_path: The full path to Simulink model.
    % varargin: User defined inputs. 
    %   'nodisplay': to disable the display mode of the model.
    %   'verif': to create a verification model that contains both the original
    %   model and pre-processed model. In order to prove the pre-processing is
    %   correct.

    global cocosim_pp_gen_verif  cocosim_pp_gen_verif_dir ;

    % 
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    
    
    nodisplay = 0;
    cocosim_pp_gen_verif = 0;
    cocosim_pp_gen_verif_dir = '';
    persistent pp_datenum_map;
    if isempty(pp_datenum_map)
        pp_datenum_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end
    try
        skip_pp = evalin('base', 'skip_pp');
    catch
        skip_pp = CoCoSimPreferences.skip_pp;
    end
    use_backup = CoCoSimPreferences.skip_defected_pp ;
    force_pp = 0;
    for i=1:numel(varargin)
    %     disp(varargin{i})
        if strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.NODISPLAY)
            nodisplay = 1;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.GEN_PP_VERIF)
            cocosim_pp_gen_verif = 1;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.SKIP_PP)
            skip_pp = 1;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.FORCE_CODE_GEN)
            force_pp = 1;
        elseif strcmp(varargin{i}, nasa_toLustre.utils.ToLustreOptions.SKIP_DEFECTED_PP)
            % use backup model, if a pp function failed, skip it.
            use_backup = 1;
        end
    end
    failed = 0;
    already_pp = NASAPPUtils.isAlreadyPP(model_path);
    if skip_pp
        if already_pp
            display_msg('SKIP_PP flag is given, the pre-processing will be skipped.', MsgType.WARNING, 'PP', '', 0);
            new_file_path = model_path;
            return;
        else
            display_msg('SKIP_PP flag is ignored if the model is not already pre-processed.', MsgType.WARNING, 'PP', '', 0);
        end
    end
    %% Creat the new model name
    [model_parent, model, ~] = fileparts(model_path);
    
    load_system(model_path);

    if already_pp
        new_model_base = model;
        new_file_path = model_path;
        save_system(model);
    else
        new_model_base = strcat(model,'_PP');
        new_file_path = fullfile(model_parent,strcat(new_model_base, '.slx'));
        %close it without saving it
        close_system(new_model_base,0);
        if exist(new_file_path, 'file'), delete(new_file_path); end
        %copyfile(model_path, new_file_path); 
        save_system(model, new_file_path);
    end

    display_msg(['Loading ' new_file_path ], MsgType.INFO, 'PP', '', 0);
    load_system(new_file_path);
    
    % DO not remove to support as many blocks as possible.
    %BreakUserLinks
    save_system(new_model_base,[],'BreakUserLinks',true)
    %% Make sure model compile
    failed = CompileModelCheck_pp( new_model_base );
    if failed
        msg = sprintf('Make sure model "%s" can be compiled', new_model_base);
        errordlg(msg, 'CoCoSim_PP') ;
        return;
    end
    %% check if there is no need for pre-processing if the model was not changed from the last pp.
    if already_pp && ~force_pp
        if isKey(pp_datenum_map, new_file_path)
            FileInfo = dir(new_file_path);
            pp_datenum = pp_datenum_map(new_file_path);
            [Y, M, D, H, MN, S] = datevec(FileInfo.datenum);
            [Y2, M2, D2, H2, MN2, S2] = datevec(pp_datenum);
            % we ignore seconds
            if Y <= Y2 && M <= M2 && D <= D2 && H <= H2 && MN <= MN2 && abs(S - S2) <= 15
                display_msg('Skipping pre-processing step. No modifications have been made to the model.', MsgType.RESULT, 'PP', '', 0);
                if ~nodisplay
                    open(new_file_path);
                end
                return;
            end
        end
    end
    %% If generation of verification template for each block pre-processed was 
    % asked
    addpath(model_parent);
    if cocosim_pp_gen_verif
        cocosim_pp_gen_verif_dir = fullfile(model_parent ,strcat(model, 'PP_Validation'));
        if ~exist(cocosim_pp_gen_verif_dir,'dir')
            mkdir(cocosim_pp_gen_verif_dir);
        end
        addpath(cocosim_pp_gen_verif_dir);
    end


    %% Creating a cache copy to process
    if ~already_pp
        hws = get_param(new_model_base, 'modelworkspace') ;
        hws.assignin('already_pp', 1);
    end

    display_msg('Loading libraries', MsgType.INFO, 'PP', '', 0);
    if ~bdIsLoaded('gal_lib'); load_system('gal_lib.slx'); end
    if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end



    %% Order functions
    global ordered_pp_functions;
    if isempty(ordered_pp_functions)
        pp_config;
    end
    %% sort functions calls
    oldDir = pwd;
    warning off
    display_msg('Start Pre-processing the model', MsgType.INFO, 'PP', '', 0);
    for i=1:numel(ordered_pp_functions)
        [dirname, func_name, ~] = fileparts(ordered_pp_functions{i});
        cd(dirname);
        if bdIsDirty(new_model_base) && use_backup
            %make sure to save the previous successful pp.
            save_system(new_model_base);
        end
        fh = str2func(func_name);
        try
            display_msg(['runing ' func2str(fh)], MsgType.INFO, 'PP', '', 1);
            if nargout(fh) == 2
                [~, errors_msg] = fh(new_model_base);
                for j=1:numel(errors_msg)
                    display_msg(errors_msg{j}, MsgType.WARNING, func2str(fh), '');
                end
            else
                fh(new_model_base);
            end
            if bdIsDirty(new_model_base) && use_backup
                % check if the model still compiles and the executed pp did not
                % break it.
                code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
                try
                    warning off;
                    evalin('base',code_on);
                catch me
                    display_msg(['Pre-processing ' func2str(fh) ' Failed'], MsgType.WARNING, 'PP', '');
                    display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
                    display_msg(['Skipping ' func2str(fh)], MsgType.WARNING, 'PP', '');
                    restore_ppmodel(new_model_base, new_file_path);
                    continue;
                end
                code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
                evalin('base',code_off);
            end
        catch me
            display_msg(['can not run ' func2str(fh)], MsgType.WARNING, 'PP', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
            if use_backup
                display_msg(['Skipping ' func2str(fh)], MsgType.WARNING, 'PP', '');
                restore_ppmodel(new_model_base, new_file_path);
            end
        end

    end
    % warning on
    cd(oldDir);
    save_system(new_model_base)
    % save_ppmodel(new_model_base, new_file_path)
    if ~nodisplay
        open(new_file_path);
    end
    %% Make sure model compile
    failed = CompileModelCheck_pp( new_model_base );
    if failed
        return;
    end
    % Exporting the model to the mdl CoCoSim compatible file format

    display_msg('Saving simplified model', MsgType.INFO, 'PP', '', 0);





    display_msg(['Simplified model path: ' new_file_path], MsgType.INFO, 'PP', '');
    display_msg('Done with the simplification', MsgType.INFO, 'PP', '');
    pp_datenum_map(new_file_path) = now;
end

%%
function save_ppmodel(new_model_base, new_file_path)
    save_system(new_model_base,new_file_path,'OverwriteIfChangedOnDisk',true);
end
function restore_ppmodel(new_model_base, new_file_path)
    % close without saving
    close_system(new_model_base, 0);
    load_system(new_file_path);
end