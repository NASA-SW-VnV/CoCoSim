
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get If the "blk" is the one abstracted by "contract"
% to use is, blk and contract are objects
function res = isAbstractedByContract(blk, contract)
    if ischar(blk) || isnumeric(blk)
        try
            blk = get_param(blk, 'Object');
        catch me
            display_msg('Function SLX2LustUtils.isAbstractedByContract should be called over structures',...
                MsgType.ERROR, 'SLX2LustUtils.isAbstractedByContract', '');
            display_msg(me.getReport(),...
                MsgType.DEBUG, 'SLX2LustUtils.isAbstractedByContract', '');
        end
    end
    if ischar(contract) || isnumeric(contract)
        try
            contract = get_param(contract, 'Object');
        catch me
            display_msg('Function SLX2LustUtils.isAbstractedByContract should be called over structures',...
                MsgType.ERROR, 'SLX2LustUtils.isAbstractedByContract', '');
            display_msg(me.getReport(),...
                MsgType.DEBUG, 'SLX2LustUtils.isAbstractedByContract', '');
        end
    end
    blk_connextivity_str = {};
    dstPort = 0;
    for j=1:numel(blk.PortConnectivity)
        x = blk.PortConnectivity(j);
        if isempty(x.SrcBlock)
            % SrcBlock will be the blk itself and SrcPort is Type atribute
            blk_connextivity_str{end+1} = sprintf('%.5f_%d', blk.Handle, dstPort);
            dstPort = dstPort + 1;
        else
            blk_connextivity_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
        end
    end

    contract_connextivity_str = {};
    for j=1:numel(contract.PortConnectivity)
        x = contract.PortConnectivity(j);
        if isempty(x.SrcBlock)
            continue;
        else
            contract_connextivity_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
        end
    end
    res = ~any(~ismember(contract_connextivity_str, blk_connextivity_str));
end
