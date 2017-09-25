function [new_ir] = stateflow_IR_pp(new_ir, output_dir, print_in_file)
% stateflow_IR_pp pre-process internal representation of stateflow. For
% example change Simulink datatypes (int32, ...) to lustre datatypes (int,
% real, bool).
% This function call SFIR_PP_config to choose which functions to call and
% in which order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin ==0 || isempty(new_ir) || ~isa(new_ir, 'Program')
    display_msg('please provide Stateflow IR while calling stateflow_IR_pp',...
        MsgType.ERROR, 'stateflow_IR_pp', '');
    return;
end
if nargin < 2 || isempty(output_dir)
    output_dir = pwd;
end
if nargin < 3 || isempty(print_in_file)
    print_in_file = 0;
end
global sfIR_pp_handled_functions sfIR_pp_unhandled_functions sfIR_pp_order_map;
SFIR_PP_config;
if isempty(sfIR_pp_order_map)
    warning('Order map ''pp_order_map'' has not been defined. Please check pp_order.m');
    sfIR_pp_order_map = containers.Map();
end
if isempty(sfIR_pp_handled_functions)
    warning('Order map ''sfIR_pp_handled_functions'' has not been defined. Please check pp_order.m');
end
if isempty(sfIR_pp_unhandled_functions)
    warning('Order map ''sfIR_pp_unhandled_functions'' has not been defined. Please check pp_order.m');
end

pp_path = fileparts(mfilename('fullpath'));


%% Create supported functions
handled_functions_map = containers.Map();

for i=1:numel(sfIR_pp_handled_functions)
    [library_path, ~,~] = fileparts(sfIR_pp_handled_functions{i});
    full_path = fullfile(pp_path, sfIR_pp_handled_functions{i});
    handled_blocks_i = dir(full_path);
    if ~handled_functions_map.isKey(library_path)
        handled_functions_map(library_path) = handled_blocks_i;
    else
        handled_functions_map(library_path) = [handled_functions_map(library_path); handled_blocks_i];
    end
end

unhandled_functions_map = containers.Map();
for i=1:numel(sfIR_pp_unhandled_functions)
    [library_path, ~,~] = fileparts(sfIR_pp_unhandled_functions{i});
    full_path = fullfile(pp_path, sfIR_pp_unhandled_functions{i});
    handled_blocks_i = dir(full_path);
    if ~unhandled_functions_map.isKey(library_path)
        unhandled_functions_map(library_path) = handled_blocks_i;
    else
        unhandled_functions_map(library_path) = [unhandled_functions_map(library_path); handled_blocks_i];
    end
end

%% delete unsupported functions from supported functions map
% s = handled_functions_map('fields');
% for i=1:numel(s)
%     s(i)
% end
for key=unhandled_functions_map.keys
    if handled_functions_map.isKey(key)
        v = handled_functions_map(key{1});
        unv = unhandled_functions_map(key{1});
        A = {v.name};
        B = {unv.name};
        [~, ia] = setdiff(A,B);
        
        v = v(ia);
        handled_functions_map(key{1}) = v;
    end
end

% unhandled_functions_map('fields')
% s = handled_functions_map('fields');
% for i=1:numel(s)
%     s(i)
% end

handled_functions = [];
for val = handled_functions_map.values
    handled_functions = [handled_functions; val{1}];
end
if ~isempty(handled_functions)
    a2 = {handled_functions.folder};
    b2 = {handled_functions.name};
    handeled_full_paths=cellfun(@(x,y) [x filesep y],a2', b2','un',0);
else
    handeled_full_paths = {};
end

%% flatten pp_order_map
ordered_functions = [];

for key= sort(cell2mat(sfIR_pp_order_map.keys))
    
    v_list = sfIR_pp_order_map(key);
    for i=1:numel(v_list)
        v = v_list{i};
        full_path = fullfile(pp_path, v);
        if key == -1
            % remove it from handled functions
            if contains(full_path, '*')
                index = find(ismember(handeled_full_paths, {full_path}));
                handled_functions(index) = [];
                handeled_full_paths(index) = [];
            else
                ordered_blocks_i = dir(full_path);
                for j=1:numel(ordered_blocks_i)
                    full_path = fullfile(ordered_blocks_i(j).folder, ordered_blocks_i(j).name);
                    index = find(ismember(handeled_full_paths, {full_path}));
                    handled_functions(index) = [];
                    handeled_full_paths(index) = [];
                end
            end
        else
            ordered_blocks_i = dir(full_path);
            ordered_functions = [ordered_functions; ordered_blocks_i];
        end
    end
    
end
%% remove duplicated functions
if ~isempty(ordered_functions)
    a = {ordered_functions.folder};
    b = {ordered_functions.name};
    c = cellfun(@(x,y) [x filesep y],a', b','un',0);
    [~,ii] = unique(c,'stable');
    ordered_functions = ordered_functions(ii);
end
%% Add handled functions that were not ordered. They will have the lowest priority
if isempty(ordered_functions) || numel(handled_functions) < numel(ordered_functions)
    ordered_functions = handled_functions;
elseif numel(handled_functions) > numel(ordered_functions)
    a = {ordered_functions.folder};
    b = {ordered_functions.name};
    ordered_full_paths=cellfun(@(x,y) [x filesep y],a', b','un',0);
    [~, ia] = setdiff(handeled_full_paths, ordered_full_paths);
    diff = handled_functions(ia);
    ordered_functions = [ordered_functions; diff];
    
end


%% sort functions calls
oldDir = pwd;
if ~isempty(ordered_functions) && isfield(ordered_functions(1), 'folder')
    for i=1:numel(ordered_functions)
        dirname = ordered_functions(i).folder;
        cd(dirname);
        fh = str2func(ordered_functions(i).name(1:end-2));
        try
            display_msg(['runing ' func2str(fh)], MsgType.INFO, 'Stateflow_IRPP', '');
            new_ir = fh(new_ir);
        catch me
            display_msg(['can not run ' func2str(fh)], MsgType.ERROR, 'Stateflow_IRPP', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'Stateflow_IRPP', '');
        end
        
    end
end
cd(oldDir);
%%  Exporting the IR

if print_in_file
    json_text = jsonencode(new_ir);
    json_text = regexprep(json_text, '\\/','/');
    fname = fullfile(output_dir, strcat(SFIRUtils.adapt_root_name(new_ir.name),'_SFIR_pp_tmp.json'));
    fname_formatted = fullfile(output_dir, strcat(SFIRUtils.adapt_root_name(new_ir.name),'_SFIR_pp.json'));
    fid = fopen(fname, 'w');
    if fid==-1
        display_msg(['Couldn''t create file ' fname], MsgType.ERROR, 'Stateflow_IRPP', '');
    else
        fprintf(fid,'%s\n',json_text);
        fclose(fid);
        cmd = ['cat ' fname ' | python -mjson.tool > ' fname_formatted];
        try
            [status, output] = system(cmd);
            if status~=0
                display_msg(['file is not formatted ' output], MsgType.ERROR, 'Stateflow_IRPP', '');
                fname_formatted = fname;
            end
        catch
            fname_formatted = fname;
        end
        display_msg(['IR has been written in ' fname_formatted], MsgType.RESULT, 'Stateflow_IRPP', '');
    end
end


display_msg('Done with the pre-processing', MsgType.INFO, 'Stateflow_IRPP', '');
end