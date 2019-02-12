
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lus_dt] = SignalHierarchyLusDT(blk, SignalHierarchy)
    %isBus = false;
    lus_dt = {};
    try
        if ~isfield(SignalHierarchy, 'SignalName')
            display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
            blk.Origin_path), MsgType.ERROR, '', '');
            lus_dt = 'real';
            return;
        end
        SignalName = SignalHierarchy.SignalName;
        if isempty(SignalHierarchy.SignalName) ...
                || SLXUtils.isSimulinkBus(SignalHierarchy.BusObject)
            SignalName = SignalHierarchy.BusObject;
        end
        if isempty(SignalName)
            if  ~isfield(SignalHierarchy, 'Children') ...
                    || isempty(SignalHierarchy.Children)
                lus_dt = 'real';
                display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
                    blk.Origin_path), MsgType.ERROR, '', '');
                return;
            else
                for i=1:numel(SignalHierarchy.Children)
                    [lus_dt_i] = ...
                        nasa_toLustre.utils.SLX2LusUtils.SignalHierarchyLusDT(blk, SignalHierarchy.Children(i));
                    if iscell(lus_dt_i)
                        lus_dt = [lus_dt, lus_dt_i];
                    else
                        lus_dt{end+1} = lus_dt_i;
                    end
                end
                return;
            end
        end
        isBus = SLXUtils.isSimulinkBus(SignalName);
        if isBus
            lus_dt =...
                nasa_toLustre.utils.SLX2LusUtils.getLustreTypesFromBusObject(SignalName);
        else
            p = find_system(bdroot(blk.Origin_path),...
                'FindAll', 'on', ...
                'Type', 'port',...
                'PortType', 'outport', ...
                'SignalNameFromLabel', SignalName );
            BusCreatorFound = false;
            for i=1:numel(p)
                p_parent=  get_param(p(i), 'Parent');
                p_parentObj = get_param(p_parent, 'Object');
                if isequal(p_parentObj.BlockType, 'BusCreator')
                    BusCreatorFound = true;
                    break;
                end
            end
            if BusCreatorFound
                lus_dt = nasa_toLustre.utils.SLX2LusUtils.getBusCreatorLusDT(...
                    get_param(p_parentObj.Parent, 'Object'), ...
                    p_parentObj, ...
                    get_param(p(i), 'PortNumber'));
            elseif numel(p) >= 1
                compiledDT = SLXUtils.getCompiledParam(p(1), 'CompiledPortDataType');
                [lus_dt, ~, ~, ~] = ...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(compiledDT);
                CompiledPortWidth = SLXUtils.getCompiledParam(p(1), 'CompiledPortWidth');
                if iscell(lus_dt) && numel(lus_dt) < CompiledPortWidth
                    lus_dt = arrayfun(@(x) lus_dt{1}, (1:CompiledPortWidth), ...
                        'UniformOutput', 0);
                else
                    lus_dt = arrayfun(@(x) lus_dt, (1:CompiledPortWidth), ...
                        'UniformOutput', 0);
                end
            else
                lus_dt = 'real';
            end
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'getBlockOutputsNames', '');
        lus_dt = 'real';
    end
end
