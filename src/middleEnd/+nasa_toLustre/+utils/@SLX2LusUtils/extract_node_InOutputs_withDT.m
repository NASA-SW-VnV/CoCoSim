
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [names, names_withNoDT] = extract_node_InOutputs_withDT(subsys, type, xml_trace)
    %get all blocks names
    fields = fieldnames(subsys.Content);

    % remove blocks without BlockType (e.g annotations)
    fields = ...
        fields(...
        cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));

    % get only blocks with BlockType=type
    Portsfields = ...
        fields(...
        cellfun(@(x) strcmp(subsys.Content.(x).BlockType,type), fields));

    isInsideContract = nasa_toLustre.utils.SLX2LusUtils.isContractBlk(subsys);
    % sort the blocks by order of their ports
    ports = cellfun(@(x) str2num(subsys.Content.(x).Port), Portsfields);
    [~, I] = sort(ports);
    Portsfields = Portsfields(I);
    names = {};
    names_withNoDT = {};
    for i=1:numel(Portsfields)
        block = subsys.Content.(Portsfields{i});
        [names_withNoDT_i, names_i] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(subsys, block);
        names = [names, names_i];
        names_withNoDT = [names_withNoDT, names_withNoDT_i];
        % traceability
        width = numel(names_withNoDT_i);
        IsNotInSimulink = false;
        for index=1:numel(names_withNoDT_i)
            xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
        end
    end
    if strcmp(type, 'Inport')
        % add enable port to the node inputs, if ShowOutputPort is
        % on
        enablePortsFields = fields(...
            cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'EnablePort'), fields));
        if ~isempty(enablePortsFields) ...
                && strcmp(subsys.Content.(enablePortsFields{1}).ShowOutputPort, 'on')
            [names_withNoDT_i, names_i] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(enablePortsFields{1}));
            names = [names, names_i];
            names_withNoDT = [names_withNoDT, names_withNoDT_i];
            % traceability
            width = numel(names_withNoDT_i);
            IsNotInSimulink = false;
            block = subsys.Content.(enablePortsFields{1});
            for index=1:numel(names_withNoDT_i)
                xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                    block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
            end
        end
        % add trigger port to the node inputs, if ShowOutputPort is
        % on
        triggerPortsFields = fields(...
            cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'TriggerPort'), fields));
        if ~isempty(triggerPortsFields) ...
                && strcmp(subsys.Content.(triggerPortsFields{1}).ShowOutputPort, 'on')
            [names_withNoDT_i, names_i] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(triggerPortsFields{1}));
            names = [names, names_i];
            names_withNoDT = [names_withNoDT, names_withNoDT_i];
            % traceability
            width = numel(names_withNoDT_i);
            IsNotInSimulink = false;
            block = subsys.Content.(triggerPortsFields{1});
            for index=1:numel(names_withNoDT_i)
                xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                    block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
            end
        end
    end

end
