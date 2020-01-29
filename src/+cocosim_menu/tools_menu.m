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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function schema = tools_menu(varargin)
    %tools_menu Define the custom menu function for CoCoSim.

    schema = sl_container_schema;
    schema.label = 'CoCoSim';
    schema.statustip = 'Automated Analysis Framework';
    schema.autoDisableWhen = 'Busy';

    [cocosim_menu_root, ~, ~] = fileparts(mfilename('fullpath'));
    src_root = fileparts(cocosim_menu_root);
    backEnd_root = fullfile(src_root, 'backEnd');
    menue_items = {};
    menue_items{end + 1} = fullfile(backEnd_root, 'unsupported_blocks','unsupportedBlocksMenu.m');
    menue_items{end + 1} = fullfile(backEnd_root, 'guidelines','checkGuidelinesMenu.m');
    menue_items{end + 1} = fullfile(backEnd_root, 'verification','verifyMenu.m');
    menue_items{end + 1} = fullfile(backEnd_root, 'designErrorDetection','dedMenu.m');
    
    %TODO: test case generation should be adapted to new compiler and dataset
    %signals.
    menue_items{end + 1} = fullfile(backEnd_root, 'test_case_generation','TestCaseGenMenu.m');
    
    %TODO: needs Zustre to support contracts
    %menue_items{end + 1} = fullfile(backEnd_root, 'generate_invariants','generateInvariantsMenu.m');
    
    %TODO: add documentation of how to use
    menue_items{end + 1} = fullfile(backEnd_root, 'importLustreRequirements','importLusReqMenu.m');
    
    menue_items{end + 1} = fullfile(backEnd_root, 'generate_code','generateCodeMenu.m');
    menue_items{end + 1} = fullfile(backEnd_root, 'extra_options','extraOptionsMenu.m');
    menue_items{end + 1} = @cocosim_menu.preferences_menu;

    iif = MatlabUtils.iif();
    obj2Handle = @(x) iif( isa(x, 'function_handle'), @() x, ...
        true, @() MenuUtils.funPath2Handle(x));
    callbacks = cellfun(obj2Handle, menue_items,...
        'UniformOutput', false);
    schema.childrenFcns = cellfun(@(x) {@MenuUtils.addTryCatch, x}, callbacks, 'UniformOutput', false);

end

