%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SFIR_PP_config let the user defines the functions to be called in the
%pre-processing of stateflow IR.




%% TODO: add blocks to be pre-processed or to be ignored
% Here are the functions to be called (or to be ignored) in the pre-processing.
% examples:
% -To add all functions in `fields` folder, add 'fields/*.m'
% -To add all functions in `fields` except `funX.m`.
%   Add 'fields/*.m' to sfIR_pp_handled_functions and
%   Add 'fields/funX.m' to sfIR_pp_unhandled_functions
% -To impose a specific order of functions calls see above.
global ordered_sfIR_pp_functions priority_sfIR_pp_map;

% add both std_pp and pp2
sfIR_pp_handled_functions = {'fields/*.m'};
% To not call "funX" we may add it to the following list, or give
% it an order -1 in sfIR_pp_order_map (see next TODO).
sfIR_pp_unhandled_functions = {'fields/funX.m'};


%% TODO: define orders
% pp_order_map is a Map with keys define the priority and Values define
% functions list
sfIR_pp_order_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');

sfIR_pp_order_map(-1) = {'fields/funX.m'}; % -1 means not to call

sfIR_pp_order_map(0) = {'fields/*.m'};% 0 means all functions inside fields will be called first.



[ordered_sfIR_pp_functions, priority_sfIR_pp_map]  = ...
    PP_Utils.order_pp_functions(sfIR_pp_order_map, sfIR_pp_handled_functions, sfIR_pp_unhandled_functions);
