function [new_file_path, status] = cocosim_pp(model_path, varargin)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global cocosim_pp_gen_verif  cocosim_pp_gen_verif_dir;

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
    skip_pp = 0;
end
use_backup = 0 ;
for i=1:numel(varargin)
%     disp(varargin{i})
    if strcmp(varargin{i}, 'nodisplay')
        nodisplay = 1;
    elseif strcmp(varargin{i}, 'verif')
        cocosim_pp_gen_verif = 1;
    elseif strcmp(varargin{i}, 'skip_pp')
        skip_pp = 1;
    elseif strcmp(varargin{i}, 'use_backup')
        % use backup model, if a pp function failed, skip it.
        use_backup = 1;
    end
end
status = 0;
if skip_pp
    display_msg('SKIP_PP flag is given, the pre-processing will be skipped.', MsgType.INFO, 'PP', '');
    new_file_path = model_path;
    return;
end
%% Creat the new model name
[model_parent, model, ext] = fileparts(model_path);
already_pp = false;
load_system(model_path);

if SLXUtils.isAlreadyPP(model_path)
    already_pp = true;
    new_model_base = model;
    new_file_path = model_path;
    save_system(model);
else
    new_model_base = strcat(model,'_PP');
    new_file_path = fullfile(model_parent,strcat(new_model_base, ext));
    %close it without saving it
    close_system(new_model_base,0);
end


if ~already_pp; delete(new_file_path); end
if ~already_pp; copyfile(model_path, new_file_path); end
display_msg(['Loading ' new_file_path ], MsgType.INFO, 'PP', '');
load_system(new_file_path);
%BreakUserLinks
save_system(new_model_base,[],'BreakUserLinks',true)
%% Make sure model compile
status = CompileModelCheck_pp( new_model_base );
if status
    return;
end
%% check if there is no need for pre-processing if the model was not changed from the last pp.
if already_pp
    if isKey(pp_datenum_map, new_file_path)
        FileInfo = dir(new_file_path);
        pp_datenum = pp_datenum_map(new_file_path);
        [Y, M, D, H, MN, S] = datevec(FileInfo.datenum);
        [Y2, M2, D2, H2, MN2, S2] = datevec(pp_datenum);
        % we ignore seconds
        if Y <= Y2 && M <= M2 && D <= D2 && H <= H2 && MN <= MN2 && abs(S - S2) <= 15
            display_msg('Skipping pre-processing step. No modifications have been made to the model.', MsgType.RESULT, 'PP', '');
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

display_msg('Loading libraries', MsgType.INFO, 'PP', '');
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
for i=1:numel(ordered_pp_functions)
    [dirname, func_name, ~] = fileparts(ordered_pp_functions{i});
    cd(dirname);
    if bdIsDirty(new_model_base) && use_backup
        %make sure to save the previous successful pp.
        save_system(new_model_base);
    end
    fh = str2func(func_name);
    try
        display_msg(['runing ' func2str(fh)], MsgType.INFO, 'PP', '');
        fh(new_model_base);
        if bdIsDirty(new_model_base) && use_backup
            % check if the model still compiles and the executed pp did not
            % break it.
            code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
            try
                warning off;
                evalin('base',code_on);
            catch me
                display_msg(['can not run ' func2str(fh)], MsgType.WARNING, 'PP', '');
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
status = CompileModelCheck_pp( new_model_base );
if status
    return;
end
% Exporting the model to the mdl CoCoSim compatible file format

display_msg('Saving simplified model', MsgType.INFO, 'PP', '');




    
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