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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%GUIDLINES_ORDER let the user order guidelines checking functions
% functions are ordered by ascending order of priority.
% 0 is the highest priority
% Give functions a priority -1 to not be called.
% the function path should always start from the library name
% you can call other libraries also

global ordered_guidelines_functions priority_guidelines_map;


%% TODO: add imported libraries paths
% In our case "main" library import both "simulink_guidelines" and "stateflow_guidelines" libraries
addpath(genpath(fullfile(config_path, 'simulink_guidelines')));
addpath(genpath(fullfile(config_path, 'stateflow_guidelines')));
addpath(genpath(fullfile(config_path, 'matlab_guidelines')));

%% TODO: add guidelines to be checked or to be ignored
% Here are the functions to be called (or to be ignored) in the
% guidelines checking.
% examples:
% -To add all supported checks in `simulink`, add 'simulink/*.m'
% -To add all supported blocks in `stateflow` except `x.m`.
%   Add 'stateflow/*.m' to guidelines_handled_blocks and
%   Add 'stateflow/x.m' to guidelines_unhandled_blocks
% -To impose a specific order of functions calls see later.

% add both std_pp and nasa_pp
guidelines_handled_blocks = {'simulink_guidelines/*.m', 'stateflow_guidelines/*.m', 'matlab_guidelines/*.m'};
% To not call atomic_process we may add it to the following list, or
% give it an order -1 in guidelines_order_map (see next TODO).
guidelines_unhandled_blocks = {};
%compile process is called in the end of cocosim_pp.


%% TODO: define orders
% guidelines_order_map is a Map with keys define the priority and Values define
% functions list
guidelines_order_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');

% -1 means not to call
guidelines_order_map(-1) = {};

% small number has the highest priority starting from zero
guidelines_order_map(0) = {'simulink_guidelines/*.m'};
guidelines_order_map(1) = {'stateflow_guidelines/*.m'};
guidelines_order_map(2) = {'matlab_guidelines/*.m'};


[ordered_guidelines_functions, priority_guidelines_map]  = ...
    PPConfigUtils.order_pp_functions(guidelines_order_map, guidelines_handled_blocks, ...
    guidelines_unhandled_blocks);
