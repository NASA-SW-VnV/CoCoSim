%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = unsupportedBlocksMenu(callbackInfo)
schema = sl_container_schema;
schema.label = 'Check Compatibility';
schema.statustip = 'Check compatibility of your model with CoCoSim';
schema.autoDisableWhen = 'Busy';
[~, model_name] = MenuUtils.get_file_name(gcs);
schema.childrenFcns = {@CheckModel, @(x) CheckSubsystem(model_name, x)};
end


function schema = CheckModel(callbackInfo)
schema = sl_action_schema;
schema.label = 'Model';
schema.callback = @(x) UnsupportedFunctionCallback(0,'', x);
end

function UnsupportedFunctionCallback(isSubsystem, SubsystemPath, callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
if ~isSubsystem
    unsupportedOptions= ToLustreUnsupportedBlocks(model_full_path);
else
    %     unsupportedOptions= ToLustreUnsupportedBlocks(model_full_path, SubsystemName);
    msgbox(sprintf('I am running %s', SubsystemPath));
end

end


function schema = CheckSubsystem(SubsystemPath, callbackInfo)
SubsysList = find_system(SubsystemPath, 'SearchDepth',1, 'BlockType', 'SubSystem');
SubsysList = SubsysList(~strcmp(SubsysList, SubsystemPath));
if isempty(SubsysList)
    names = regexp(SubsystemPath,'/','split');
    subsystemName = names{end};
    schema = sl_action_schema;
    if numel(names) == 1
        schema.label = 'Selected Subsystem';
        schema.state = 'Disabled';
    else
        schema.label = subsystemName;
    end
    schema.callback = @(x) UnsupportedFunctionCallback(1,SubsystemPath, x);
else
    schema = sl_container_schema;
    names = regexp(SubsystemPath,'/','split');
    if numel(names) == 1
        schema.label = 'Selected Subsystem';
    else
        schema.label = regexprep(names{end}, '(\\n|\n)', ' ');
    end
    schema.statustip = 'Check compatibility for specific subsystem';
    schema.autoDisableWhen = 'Busy';
    callbacks = {};
    for i=1:numel(SubsysList)
        callbacks{i} =  @(x) CheckSubsystem(SubsysList{i}, x);
    end
    schema.childrenFcns = callbacks;
end

end

