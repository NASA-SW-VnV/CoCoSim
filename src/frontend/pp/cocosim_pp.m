function [new_file_path] = cocosim_pp(file_path, varargin)
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
global pp_order_map pp_handled_blocks pp_unhandled_blocks;
if isempty(pp_order_map)
    warning('Order map ''pp_order_map'' has not been defined. Please check pp_order.m');
    pp_order_map = containers.Map();
end
if isempty(pp_handled_blocks)
    warning('Order map ''pp_handled_blocks'' has not been defined. Please check pp_order.m');
end
if isempty(pp_unhandled_blocks)
    warning('Order map ''pp_unhandled_blocks'' has not been defined. Please check pp_order.m');
end
nodisplay = 0;
cocosim_pp_gen_verif = 0;
cocosim_pp_gen_verif_dir = '';
for i=1:numel(varargin)
    if strcmp(varargin{i}, 'nodisplay')
        nodisplay = 1;
    elseif strcmp(varargin{i}, 'verif')
        cocosim_pp_gen_verif = 1;
    end
end

pp_path = fileparts(mfilename('fullpath'));

%% Creat the new model name
[model_parent, model, ext] = fileparts(file_path);
already_pp = 0;
if strcmp(model(end-2:end), '_PP')
    load_system(file_path);
    annotations = find_system(model,'FindAll','on','Type','annotation','MarkupType', 'markup', 'Name', 'cocosim_pp');
    if isempty(annotations)
        new_model_base = strcat(model,'_PP');
        new_file_path = fullfile(model_parent,strcat(new_model_base, ext));
    else
        already_pp = 1;
        new_model_base = model;
        new_file_path = file_path;
    end
else
    new_model_base = strcat(model,'_PP');
    new_file_path = fullfile(model_parent,strcat(new_model_base, ext));
end
%close it without saving it
close_system(new_model_base,0);
if ~already_pp; delete(new_file_path); end

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
if ~already_pp; copyfile(file_path, new_file_path); end
display_msg(['Loading ' new_file_path ], MsgType.INFO, 'PP', '');
load_system(new_file_path);
if ~already_pp
    add_block('built-in/Note', ...
    strcat(new_model_base, '/cocosim_pp'), ...
    'MarkupType', 'markup')
end

display_msg('Loading library', MsgType.INFO, 'PP', '');
if ~bdIsLoaded('gal_lib'); load_system('gal_lib.slx'); end



%% Preprocess
%% Create supported blocks
display_msg('Looking for CoCoSim non-supported blocks', MsgType.INFO, 'PP', '');
handled_blocks_map = containers.Map();

for i=1:numel(pp_handled_blocks)
    [library_path, ~,~] = fileparts(pp_handled_blocks{i});
    full_path = fullfile(pp_path, pp_handled_blocks{i});
    handled_blocks_i = dir(full_path);
    if ~handled_blocks_map.isKey(library_path)
        handled_blocks_map(library_path) = handled_blocks_i;
    else
        handled_blocks_map(library_path) = [handled_blocks_map(library_path); handled_blocks_i];
    end
end

unhandled_blocks_map = containers.Map();
for i=1:numel(pp_unhandled_blocks)
    [library_path, ~,~] = fileparts(pp_unhandled_blocks{i});
    full_path = fullfile(pp_path, pp_unhandled_blocks{i});
    handled_blocks_i = dir(full_path);
    if ~unhandled_blocks_map.isKey(library_path)
        unhandled_blocks_map(library_path) = handled_blocks_i;
    else
        unhandled_blocks_map(library_path) = [unhandled_blocks_map(library_path); handled_blocks_i];
    end
end

%% delete unsupported blocks from supported blocks map
for key=unhandled_blocks_map.keys
    if handled_blocks_map.isKey(key)
        v = handled_blocks_map(key{1});
        unv = unhandled_blocks_map(key{1});
        A = {v.name};
        B = {unv.name};
        [~, ia] = setdiff(A,B);
        
        v = v(ia);
        handled_blocks_map(key{1}) = v;
    end
end

handled_blocks = [];
for val = handled_blocks_map.values
    handled_blocks = [handled_blocks; val{1}];
end
a2 = {handled_blocks.folder};
b2 = {handled_blocks.name};
handeled_full_paths=cellfun(@(x,y) [x '/' y],a2', b2','un',0);
%% flatten pp_order_map
ordered_blocks = [];

for key= sort(cell2mat(pp_order_map.keys))
    
    v_list = pp_order_map(key);
    for i=1:numel(v_list)
        v = v_list{i};
        full_path = fullfile(pp_path, v);
        if key == -1
            % remove it from handled blocks
            index = find(ismember(handeled_full_paths, {full_path}));
            handled_blocks(index) = [];
            handeled_full_paths(index) = [];
        else
            ordered_blocks_i = dir(full_path);
            ordered_blocks = [ordered_blocks; ordered_blocks_i];
        end
    end
    
end
%% remove duplicated functions
a = {ordered_blocks.folder};
b = {ordered_blocks.name};
c = cellfun(@(x,y) [x '/' y],a', b','un',0);
[~,ii] = unique(c,'stable');
ordered_blocks = ordered_blocks(ii);

%% Add handled blocks that were not ordered. They will have the lowest priority
if numel(handled_blocks) > numel(ordered_blocks)
    a = {ordered_blocks.folder};
    b = {ordered_blocks.name};
    ordered_full_paths=cellfun(@(x,y) [x '/' y],a', b','un',0);
    
    [~, ia] = setdiff(handeled_full_paths, ordered_full_paths);
    diff = handled_blocks(ia);
    ordered_blocks = [ordered_blocks; diff];
end


%% sort functions calls
oldDir = pwd;
if ~isempty(ordered_blocks) && isfield(ordered_blocks(1), 'folder')
    for i=1:numel(ordered_blocks)
        dirname = ordered_blocks(i).folder;
        cd(dirname);
        fh = str2func(ordered_blocks(i).name(1:end-2));
        cd(oldDir);
        try
            display_msg(['runing ' func2str(fh)], MsgType.INFO, 'PP', '');
            fh(new_model_base);
        catch me
            display_msg(['can not run ' func2str(fh)], MsgType.ERROR, 'PP', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
        end
        
    end
end
%% 
% Exporting the model to the mdl CoCoSim compatible file format

display_msg('Saving simplified model', MsgType.INFO, 'PP', '');
display_msg(['Simplified model path: ' new_file_path], MsgType.INFO, 'PP', '');


save_system(new_model_base,new_file_path,'OverwriteIfChangedOnDisk',true);
if ~nodisplay
    open(new_file_path);
end
    

display_msg('Done with the simplification', MsgType.INFO, 'PP', '');
end