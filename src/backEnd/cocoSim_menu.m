function schema = cocoSim_menu(varargin)
%cocoSim_menu Define the custom menu function.
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

[backEnd_root, ~, ~] = fileparts(mfilename('fullpath'));
menue_items = {};
menue_items{end + 1} = fullfile(backEnd_root, 'unsupported_blocks','unsupportedBlocksMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'guidelines','checkGuidelinesMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'verification','verifyMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'test_case_generation','TestCaseGenMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'generate_invariants','generateInvariantsMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'importLustreRequirements','importLusReqMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'generate_code','generateCodeMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'validation','validationMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'extra_options','extraOptionsMenu.m');
menue_items{end + 1} = fullfile(backEnd_root, 'preferences','preferences_menu.m');

schema.childrenFcns = cellfun(@MenuUtils.funPath2Handle, menue_items,...
                    'UniformOutput', false);

end

