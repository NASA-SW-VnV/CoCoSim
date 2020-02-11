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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SFIR_PP_config let the user defines the functions to be called in the
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

lib_path = '+nasa_toLustre/+IR_pp/+stateflow_IR_pp/+stateflow_fields';
sfIR_pp_handled_functions = {fullfile(lib_path,'*.m')};
% To not call "funX" we may add it to the following list, or give
% it an order -1 in sfIR_pp_order_map (see next TODO).
sfIR_pp_unhandled_functions = {};


%% TODO: define orders
% pp_order_map is a Map with keys define the priority and Values define
% functions list
sfIR_pp_order_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');


sfIR_pp_order_map(0) = {fullfile(lib_path,'SFunction_SFIR_PP.m')};
sfIR_pp_order_map(1) = {fullfile(lib_path,'transitionSource_SFIR_pp.m')};
sfIR_pp_order_map(2) = {fullfile(lib_path,'transitionLabel_SFIR_pp.m')};
sfIR_pp_order_map(3) = {fullfile(lib_path,'confirm_actions_SFIR_pp.m')};
sfIR_pp_order_map(4) = {fullfile(lib_path,'*.m')};



[ordered_sfIR_pp_functions, priority_sfIR_pp_map]  = ...
    PPConfigUtils.order_pp_functions(sfIR_pp_order_map, sfIR_pp_handled_functions, sfIR_pp_unhandled_functions);
