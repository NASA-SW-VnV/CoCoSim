%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PP_ORDER let the user order pre-processing functions
% functions are ordered by ascending order of priority.
% 0 is the highest priority
% Give functions a priority -1 to not be called.
% the function path should always start from the library name
% you can call other libraries also

global ordered_pp_functions priority_pp_map;
mat_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
    'pp_user_variables.mat');

if exist(mat_path, 'file')
    % use the user defined configuration
    display_msg('Using user defined configuration', MsgType.INFO, 'pp_order', '');
    mat_content = load(mat_path);
    ordered_pp_functions = mat_content.ordered_pp_functions;
    priority_pp_map = mat_content.priority_pp_map;
else
    %% TODO: add imported libraries paths
    % In our case "main" library import both "std_pp" and "pp2" libraries
    addpath(genpath(fullfile(config_path, 'std_pp')));
    addpath(genpath(fullfile(config_path, 'pp2')));
    
    
    %% TODO: add blocks to be pre-processed or to be ignored
    % Here are the functions to be called (or to be ignored) in the
    % pre-processing.
    % examples:
    % -To add all supported blocks in `std_pp`, add 'std_pp/blocks/*.m'
    % -To add all supported blocks in `pp2` except `atomic_process.m`.
    %   Add 'pp2/blocks/*.m' to pp_handled_blocks and
    %   Add 'pp2/blocks/atomic_process.m' to pp_unhandled_blocks
    % -To impose a specific order of functions calls see above.
    
    % add both std_pp and pp2
    pp_handled_blocks = {'std_pp/blocks/*.m',...
        'pp2/blocks/*.m'};
    % To not call atomic_process we may add it to the following list, or
    % give it an order -1 in pp_order_map (see next TODO).
    pp_unhandled_blocks = {
        'pp2/blocks/compile_process.m',...
        'pp2/blocks/blocks_position_process.m',...
        'std_pp/blocks/product_process.m'};
    %compile process is called in the end of cocosim_pp.
    
    
    %% TODO: define orders
    % pp_order_map is a Map with keys define the priority and Values define
    % functions list
    pp_order_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    
    % -1 means not to call
    pp_order_map(-1) = { ...
        'pp2/blocks/sameDT_process.m', ...
        'std_pp/blocks/gain_process.m', ...
        'std_pp/blocks/replace_variables.m', ...
        'std_pp/blocks/selector_process.m', ...
        'std_pp/blocks/product_process.m'};
    % 0 means all this functions will be called first.
    
    pp_order_map(0) = {'pp2/blocks/fixedStepDiscrete_process.m',...
        'pp2/blocks/inport_process.m', ...
        'pp2/blocks/outport_process.m' ...
        };
    
    pp_order_map(1) = {'std_pp/blocks/goto_process.m'};
    pp_order_map(2) = {'pp2/blocks/blocks_position_process.m'};
    % '*.m' means all std_pp functions have the same priority 3,
    % if a function already defined it will keep its highest priority.
    pp_order_map(3) = {'pp2/blocks/*.m', ...
        'std_pp/blocks/*.m'};
    
    pp_order_map(4) = {'pp2/blocks/atomic_process.m'};
    pp_order_map(5) = {'pp2/blocks/expand_sub_process.m'};
    
    pp_order_map(6) = {'pp2/blocks/algebric_loops_process.m'};
    
    pp_order_map(7) = {'pp2/blocks/compile_process.m'};
    
    [ordered_pp_functions, priority_pp_map]  = ...
        PP_Utils.order_pp_functions(pp_order_map, pp_handled_blocks, ...
        pp_unhandled_blocks);
end