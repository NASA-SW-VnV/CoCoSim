function [b, ShowOutputPortIsOn, TriggerType, TriggerDT] = hasTriggerPort(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fields = fieldnames(blk.Content);
    fields = ...
        fields(...
        cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
    triggerPortsFields = fields(...
        cellfun(@(x) strcmp(blk.Content.(x).BlockType,'TriggerPort'), fields));
    b = ~isempty(triggerPortsFields);

    if b
        TriggerType = blk.Content.(triggerPortsFields{1}).TriggerType;
        ShowOutputPortIsOn =  ...
            strcmp(blk.Content.(triggerPortsFields{1}).ShowOutputPort, 'on');
        if ShowOutputPortIsOn
            TriggerDT = blk.Content.(triggerPortsFields{1}).CompiledPortDataTypes.Outport{1};
        else
            TriggerDT = '';
        end
    else
        ShowOutputPortIsOn = 0;
        TriggerType = '';
        TriggerDT = '';
    end
end
