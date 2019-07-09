
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get block outputs names: inlining dimension
function [names, names_dt] = getBlockOutputsNames(parent, blk, ...
    srcPort, xml_trace)
% This function return the names of the block
% outputs.
% Example : an Inport In with dimension [2, 3] will be
% translated as : In_1, In_2, In_3, In_4, In_5, In_6.
% where In_1 = In(1,1), In_2 = In(2,1), In_3 = In(1,2),
% In_4 = In(2,2), In_5 = In(1,3), In_6 = In(2,3).
% A block is defined by its outputs, if a block does not
% have outports, like Outport block, than will be defined by its
% inports. E.g, Outport Out with width 2 -> Out_1, out_2
blksNamesDefinedByTheirInports = {'Outport', 'Goto'};
needToLogTraceability = 0;
if nargin > 3
    % this function is only called with "xml_trace" variable in
    % Block_To_Lustre classes.
    needToLogTraceability = 1;
end
names = {};
names_dt = {};
if isempty(blk) ...
        || (isempty(blk.CompiledPortWidths.Outport) ...
        && isempty(blk.CompiledPortWidths.Inport))
    return;
end
% case of block with 'auto' Type, we need to get the inports
% datatypes.
if numel(blk.CompiledPortDataTypes.Outport) == 1 ...
        && strcmp(blk.CompiledPortDataTypes.Outport{1}, 'auto') ...
        && ~isempty(blk.CompiledPortWidths.Inport)...
        && ~strcmp(blk.BlockType, 'SubSystem')
    
    if numel(blk.CompiledPortWidths.Inport) > 1 ...
            && strcmp(blk.BlockType, 'BusCreator')
        % e,g BusCreator DT is defined by all its inputs
        width = blk.CompiledPortWidths.Inport;
    else
        % e,g BusAssignment and other blocks DT are
        % defined by their first input
        width = blk.CompiledPortWidths.Inport(1);
    end
    type = 'Inports';
    
elseif isempty(blk.CompiledPortWidths.Outport) ...
        && ismember(blk.BlockType, blksNamesDefinedByTheirInports)
    width = blk.CompiledPortWidths.Inport;
    type = 'Inports';
else
    width = blk.CompiledPortWidths.Outport;
    type = 'Outports';
end

    function [names, names_dt] = blockOutputs(portNumber)
        %
        %
        names = {};
        names_dt = {};
        if strcmp(type, 'Inports')
            slx_dt = blk.CompiledPortDataTypes.Inport{portNumber};
        else
            slx_dt = blk.CompiledPortDataTypes.Outport{portNumber};
        end
        if strcmp(slx_dt, 'auto')
            if strcmp(type, 'Inports')
                % this is the case of virtual bus, we need to do back
                % propagation to find the real datatypes
                if isfield(blk, 'BusObject') && ~isempty(blk.BusObject)
                    isBus = SLXUtils.isSimulinkBus(blk.BusObject);
                    
                    if isBus
                        lus_dt =...
                            nasa_toLustre.utils.SLX2LusUtils.getLustreTypesFromBusObject(blk.BusObject);
                        isBus = false;
                    else
                        lus_dt = nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                    end
                else
                    lus_dt = nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                    isBus = false;
                end
            elseif strcmp(blk.BlockType, 'SubSystem')
                %get all blocks names
                fields = fieldnames(blk.Content);
                
                % remove blocks without BlockType (e.g annotations)
                fields = ...
                    fields(...
                    cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
                
                % get only blocks with BlockType=type
                Portsfields = ...
                    fields(...
                    cellfun(@(x) strcmp(blk.Content.(x).BlockType,'Outport'), fields));
                % get their ports number
                ports = cellfun(@(x) str2num(blk.Content.(x).Port), Portsfields);
                outportBlk = blk.Content.(Portsfields{ports == portNumber});
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT( blk, outportBlk, 1);
                isBus = false;
            else
                try
                    pH = get_param(blk.Origin_path, 'PortHandles');
                    SignalHierarchy = get_param(pH.Outport(portNumber), ...
                        'SignalHierarchy');
                    [lus_dt] = nasa_toLustre.utils.SLX2LusUtils.SignalHierarchyLusDT(...
                        blk, SignalHierarchy);
                    isBus = false;
                catch me
                    display_msg(me.getReport(), MsgType.DEBUG, 'getBlockOutputsNames', '');
                    lus_dt = 'real';
                    isBus = false;
                end
                
            end
        else
            [lus_dt, ~, ~, isBus] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
        end
        % The width should start from the port width regarding all
        % subsystem outputs
        idx = sum(width(1:portNumber-1))+1;
        for i=1:width(portNumber)
            if isBus
                for k=1:numel(lus_dt)
                    names{end+1} = nasa_toLustre.lustreAst.VarIdExpr(...
                        nasa_toLustre.utils.SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx), '_BusElem', num2str(k))));
                    names_dt{end+1} = nasa_toLustre.lustreAst.LustreVar(names{end} , lus_dt{k});
                end
            elseif iscell(lus_dt) && numel(lus_dt) == width(portNumber)
                names{end+1} = nasa_toLustre.lustreAst.VarIdExpr(...
                    nasa_toLustre.utils.SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx))));
                names_dt{end+1} = nasa_toLustre.lustreAst.LustreVar(names{end}, char(lus_dt{i}));
            else
                names{end+1} = nasa_toLustre.lustreAst.VarIdExpr(...
                    nasa_toLustre.utils.SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx))));
                names_dt{end+1} = nasa_toLustre.lustreAst.LustreVar(names{end}, char(lus_dt));
            end
            idx = idx + 1;
        end
    end
isInsideContract = nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
IsNotInSimulink = false;
if nargin >= 3 && ~isempty(srcPort) ...
        && ~strcmp(type, 'Inports') % e.g.: BusCreator as source block case
         
    port = srcPort + 1;% srcPort starts by zero
    [names, names_dt] = blockOutputs(port);
    % traceability
    if needToLogTraceability
        for index=1:numel(names)
            xml_trace.add_Var(names{index}.getId(), ...
                blk.Origin_path, port, numel(names), index, isInsideContract, IsNotInSimulink);
        end
    end
else
    for port=1:numel(width)
        [names_i, names_dt_i] = blockOutputs(port);
        names = [names, names_i];
        names_dt = [names_dt, names_dt_i];
        if needToLogTraceability
            for index=1:numel(names_i)
                xml_trace.add_Var(names_i{index}.getId(), ...
                    blk.Origin_path, port, numel(names_i), index, isInsideContract, IsNotInSimulink);
            end
        end
    end
end
end
