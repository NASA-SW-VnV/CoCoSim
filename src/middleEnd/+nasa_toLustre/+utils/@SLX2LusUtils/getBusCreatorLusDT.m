
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lus_dt = getBusCreatorLusDT(parent, srcBlk, portNumber)
    lus_dt = {};
    if strcmp(srcBlk.BlockType, 'BusCreator')
        width = srcBlk.CompiledPortWidths.Inport;
        for port=1:numel(width)
            slx_dt = srcBlk.CompiledPortDataTypes.Inport{port};
            if strcmp(slx_dt, 'auto')
                lus_dt = [lus_dt, ...
                    nasa_toLustre.utils.SLX2LusUtils.getpreBlockLusDT(parent, srcBlk, port)];
            else
                lus_dt_tmp = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
                if iscell(lus_dt_tmp)
                    lus_dt = [lus_dt, lus_dt_tmp];
                else
                    lus_dt_tmp = arrayfun(@(x) {lus_dt_tmp}, (1:width(port)), 'UniformOutput',false);
                    lus_dt = [lus_dt, lus_dt_tmp];
                end
            end
        end
    else
        pH = get_param(srcBlk.Origin_path, 'PortHandles');
        SignalHierarchy = get_param(pH.Outport(portNumber), ...
            'SignalHierarchy');
        [lus_dt] = nasa_toLustre.utils.SLX2LusUtils.SignalHierarchyLusDT(...
            srcBlk,  SignalHierarchy);
    end
end
