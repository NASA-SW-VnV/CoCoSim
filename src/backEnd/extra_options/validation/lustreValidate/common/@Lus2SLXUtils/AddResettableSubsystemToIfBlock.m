%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

function status = AddResettableSubsystemToIfBlock(model)
    %this function fix the issue of reseting blocks inside an If-Action block
    %if it is inside a Resettable Subsystem. It propagate resettable signal to
    %the If-Action Subsystems.
    %The model should be loaded.
    status = 0;
    %% get the list of Resettable subsystem
    resetBlockList = find_system(model, 'LookUnderMasks', 'all', ...
        'BlockType','ResetPort');
    resetBlockList = get_param(resetBlockList, 'Handle');
    % go over the list and apply the method.
    for i=1:numel(resetBlockList)
        ActionPortList = find_system(get_param(resetBlockList{i}, 'Parent'),...
            'LookUnderMasks', 'all', ...
            'BlockType','ActionPort');
        ActionPortList = get_param(ActionPortList, 'Handle');
        if ~isempty(ActionPortList)
            for j=1:numel(ActionPortList)
                %check if it has UnitDelay or Subsystem, if not no
                %need to process it
                ActionPortParent = get_param(ActionPortList{j}, 'Parent');
                Delays = find_system(ActionPortParent,...
                    'LookUnderMasks', 'all', ...,
                    'SearchDepth', 1,...
                    'BlockType','Delay');
                UnitDelays = find_system(ActionPortParent,...
                    'LookUnderMasks', 'all', ...
                    'SearchDepth', 1,...
                    'BlockType','UnitDelay');
                SSList = find_system(ActionPortParent,...
                    'LookUnderMasks', 'all', ...
                    'SearchDepth', 1,...
                    'BlockType','SubSystem');

                if isempty(UnitDelays) && isempty(Delays) && numel(SSList) ==1
                    continue;
                end
                display_msg(sprintf('Fixing block %s', get_param(ActionPortList{j}, 'Parent')), ...
                    MsgType.INFO, 'AddResettableSubsystemToIfBlock', '');
                try
                    status = Lus2SLXUtils.encapsulateWithReset(resetBlockList{i}, ActionPortList{j});
                    if status
                        display_msg('AddResettableSubsystemToIfBlock Failed', ...
                            MsgType.ERROR, 'AddResettableSubsystemToIfBlock', '');
                        break;
                    end
                catch me
                    display_msg(me.getReport(), ...
                        MsgType.ERROR, 'AddResettableSubsystemToIfBlock', '');
                    break;
                end
            end
        end
    end

end

