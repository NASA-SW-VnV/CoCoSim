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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%PP_ORDER let the user order pre-processing functions
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
    % In our case "main" library import both "std_pp" and "nasa_pp" libraries
    addpath(genpath(fullfile(config_path, 'std_pp')));
    addpath(genpath(fullfile(config_path, 'nasa_pp')));
    
    
    %% TODO: add blocks to be pre-processed or to be ignored
    % Here are the functions to be called (or to be ignored) in the
    % pre-processing.
    % examples:
    % -To add all supported blocks in `std_pp`, add 'std_pp/blocks/*.m'
    % -To add all supported blocks in `nasa_pp` except `atomic_process.m`.
    %   Add 'nasa_pp/blocks/*.m' to pp_handled_blocks and
    %   Add 'nasa_pp/blocks/atomic_process.m' to pp_unhandled_blocks
    % -To impose a specific order of functions calls see later.
    
    % add both std_pp and nasa_pp
    pp_handled_blocks = {'std_pp/blocks/*.m',...
        'nasa_pp/blocks/*.m'};
    % To not call atomic_process we may add it to the following list, or
    % give it an order -1 in pp_order_map (see next TODO).
    pp_unhandled_blocks = {
        'nasa_pp/blocks/CompileModelCheck_pp.m',...
        'nasa_pp/blocks/BlocksPosition_pp.m',...
        'std_pp/blocks/product_process.m'};
    %compile process is called in the end of cocosim_pp.
    
    
    %% TODO: define orders
    % pp_order_map is a Map with keys define the priority and Values define
    % functions list
    pp_order_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    
    % -1 means not to call
    % 'std_pp/blocks/goto_process.m',... %the goto_process is removing the lines labels, which cause an error for Bus Selector or Bus Creator
    pp_order_map(-1) = { ...
        'std_pp/blocks/constant_process.m', ...
        'std_pp/blocks/clock_process.m', ...
        'nasa_pp/blocks/DiscreteFIRFilter_pp.m', ... %DiscreteFIRFilter_pp requires testing. It does not pass the regression tests
        'std_pp/blocks/discrete_state_space_process.m', ...
        'std_pp/blocks/function_process.m',...
        'std_pp/blocks/from_workspace_process.m', ...
        'std_pp/blocks/gain_process.m', ...
        'nasa_pp/blocks/Inport_pp.m', ...%No need with the new IR
        'std_pp/blocks/link_process.m',...
        'std_pp/blocks/lookuptable_process.m', ...
        'std_pp/blocks/lookuptable_nD_process.m', ...
        'std_pp/blocks/pulsegenerator_process.m', ...
        'std_pp/blocks/math_process.m',...
        'std_pp/blocks/product_process.m', ...
        'std_pp/blocks/rate_transition_process.m', ...
        'std_pp/blocks/replace_variables.m', ...
        'nasa_pp/blocks/SameDataType_pp.m', ...
        'std_pp/blocks/saturation_process.m',...% it's improved and supported by nasa_pp
        'std_pp/blocks/saturation_dynamic_process.m', ...% the pre-processing is not correct, since the block is a masked subsystem, it will be handled as a masked SS.
        'std_pp/blocks/selector_process.m', ...
        'std_pp/blocks/signalbuilder_process.m', ...
        'nasa_pp/blocks/Sigbuilderblock_pp.m', ...% No need, it is supported in the translator
        'std_pp/blocks/to_workspace_process.m',...
        'std_pp/blocks/transfer_function_process.m'}; 
    
    
    
    % small number has the highest priority starting from zero
    
    % DO not remove LinkStatus_pp to support as many blocks as possible.
    pp_order_map(0) = {'nasa_pp/blocks/LinkStatus_pp.m'};
    
    % start by setting sample time to the model sample time so the
    % pre-processing will not messed it up
    pp_order_map(1) = {'nasa_pp/blocks/SampleTime_pp.m'};
    
    
    pp_order_map(2) = {'nasa_pp/blocks/ModelReference_pp.m'};
    pp_order_map(3) = {'nasa_pp/blocks/Outport_pp.m'};
    
    pp_order_map(10) = {'std_pp/blocks/integrator_process.m'};
    pp_order_map(11) = {'std_pp/blocks/discrete_integrator_process.m'};
    
    
    % '*.m' means all std_pp functions have the same priority 3,
    % if a function already defined it will keep its highest priority.
    pp_order_map(20) = {'nasa_pp/blocks/*.m', ...
        'std_pp/blocks/*.m'};
    
    pp_order_map(30) = {'std_pp/blocks/goto_process.m'};
    pp_order_map(31) = {'nasa_pp/blocks/BlocksPosition_pp.m'};
    %pp_order_map(32) = {};
    
    pp_order_map(40) = {'nasa_pp/blocks/KindContract_pp.m'};
    pp_order_map(41) = {'nasa_pp/blocks/ContractBlock_pp.m'};
    
    pp_order_map(50) = {'nasa_pp/blocks/DiscreteDerivative_pp.m'};
    pp_order_map(51) = {'nasa_pp/blocks/SampleTimeMath_pp.m'};
    
    %pp_order_map(58) = {'nasa_pp/blocks/DiscreteFIRFilter_pp.m'}; %
    %DiscreteFIRFilter_pp requires testing. It does not pass the regression
    %tests
    pp_order_map(59) = {'nasa_pp/blocks/DiscreteFilter_pp.m'};
    pp_order_map(60) = {'nasa_pp/blocks/DiscreteTransferFcn_pp.m'};
    pp_order_map(61) = {'nasa_pp/blocks/ForEach_pp.m'};
    
    
    pp_order_map(70) = {'nasa_pp/blocks/SineandCosine_pp.m'};
    pp_order_map(71) = {'nasa_pp/blocks/ForIterator_pp.m'};%It expands subsystems, it should be called before Atomic_pp
    pp_order_map(72) = {'nasa_pp/blocks/AtomicSubsystems_pp.m'};
    pp_order_map(73) = {'nasa_pp/blocks/ExpandNonAtomicSubsystems_pp.m'};
    
    pp_order_map(80) = {'nasa_pp/blocks/Gain_pp.m'};
    
    pp_order_map(90) = {'nasa_pp/blocks/FixedStepDiscreteSolver_pp.m'};
    pp_order_map(91) = {'nasa_pp/blocks/AlgebraicLoops_pp.m'};
    pp_order_map(92) = {'nasa_pp/blocks/EnableMultiTasking_pp.m'};
    
    pp_order_map(100) = {'nasa_pp/blocks/CompileModelCheck_pp.m'};
    
    [ordered_pp_functions, priority_pp_map]  = ...
        PPConfigUtils.order_pp_functions(pp_order_map, pp_handled_blocks, ...
        pp_unhandled_blocks);
end