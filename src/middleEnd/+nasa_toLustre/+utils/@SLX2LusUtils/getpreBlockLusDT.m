
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get pre block DataType for specific port,
%it is used in the case of 'auto' type.
function lus_dt = getpreBlockLusDT(parent, blk, portNumber)

    global model_struct
    lus_dt = {};
    if strcmp(blk.BlockType, 'Inport')

        if ~isempty(model_struct)
            portNumber = str2num(blk.Port);
            blk = parent;
            parent = model_struct;
        end
    end
    [srcBlk, blkOutportPort] = nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, portNumber);

    if isempty(srcBlk)
        lus_dt = {'real'};
        display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
            srcBlk.Origin_path), MsgType.ERROR, '', '');
        return;
    end
    if strcmp(srcBlk.CompiledPortDataTypes.Outport{blkOutportPort}, 'auto')
        lus_dt = nasa_toLustre.utils.SLX2LusUtils.getBusCreatorLusDT(parent, srcBlk, blkOutportPort);
    else
        width = srcBlk.CompiledPortWidths.Outport;
        slx_dt = srcBlk.CompiledPortDataTypes.Outport{blkOutportPort};
        lus_dt_tmp = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
        if iscell(lus_dt_tmp)
            lus_dt = [lus_dt, lus_dt_tmp];
        else
            lus_dt_tmp = cellfun(@(x) {lus_dt_tmp}, (1:width(blkOutportPort)), 'UniformOutput',false);
            lus_dt = [lus_dt, lus_dt_tmp];
        end
    end
end
