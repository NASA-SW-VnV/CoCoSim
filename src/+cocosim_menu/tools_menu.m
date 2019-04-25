function schema = tools_menu(varargin)
    %tools_menu Define the custom menu function for CoCoSim.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

