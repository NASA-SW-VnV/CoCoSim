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
schema.childrenFcns = {@CheckModel, @(x) CheckSubsystem(model_name, 0, x)};
end


function schema = CheckModel(callbackInfo)
schema = sl_action_schema;
schema.label = 'Model';
schema.callback = @(x) UnsupportedFunctionCallback(0,'', x);
end

function UnsupportedFunctionCallback(isSubsystem, SubsystemPath, callbackInfo)
model_full_path = MenuUtils.get_file_name(gcs);
if ~isSubsystem
    try
        ToLustreUnsupportedBlocks(model_full_path);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, '', '');
    end
else
    %     unsupportedOptions= ToLustreUnsupportedBlocks(model_full_path, SubsystemName);
    msgbox(sprintf('I am running %s', SubsystemPath));
end

end


function schema = CheckSubsystem(SubsystemPath, isAction, callbackInfo)
SubsysList = find_system(SubsystemPath, 'SearchDepth',1, 'BlockType', 'SubSystem');
SubsysList = SubsysList(~strcmp(SubsysList, SubsystemPath));
names = regexp(SubsystemPath,'/','split');
subsystemName = names{end};
if isAction
    schema = sl_action_schema;
    schema.label = subsystemName;
    schema.callback = @(x) UnsupportedFunctionCallback(1,SubsystemPath, x);
elseif isempty(SubsysList) && numel(names) == 1
    schema = sl_action_schema;
    schema.label = 'Selected Subsystem';
    schema.state = 'Disabled';
    schema.callback = @(x) UnsupportedFunctionCallback(1,SubsystemPath, x);
elseif ~isempty(SubsysList)
    schema = sl_container_schema;
    if numel(names) == 1
        schema.label = 'Selected Subsystem';
    else
        schema.label = regexprep(names{end}, '(\\n|\n)', ' ');
    end
    schema.statustip = 'Check compatibility for specific subsystem';
    schema.autoDisableWhen = 'Busy';
    callbacks = {};
    for i=1:numel(SubsysList)
        callbacks{end+1} =  @(x) CheckSubsystem(SubsysList{i},1, x);
        if hsSubsystems(SubsysList{i})
            callbacks{end+1} =  @(x) CheckSubsystem(SubsysList{i},0, x);
        end
    end
    schema.childrenFcns = callbacks;
end

end

function r = hsSubsystems(SubsystemPath)
SubsysList = find_system(SubsystemPath, 'SearchDepth',1, 'BlockType', 'SubSystem');
SubsysList = SubsysList(~strcmp(SubsysList, SubsystemPath));
r = ~isempty(SubsysList);
end