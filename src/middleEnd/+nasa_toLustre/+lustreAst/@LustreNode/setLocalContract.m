%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setLocalContract(obj, localContract)
    if iscell(localContract) && numel(localContract) == 1
        obj.localContract = localContract{1};
    elseif iscell(localContract) && numel(localContract) > 1
        display_msg(...
            sprintf(['Node %s has more than one contract.', ...
            ' A node can contain only one local contract. ', ...
            'The first one will be used.'], obj.name), ...
            MsgType.ERROR, 'LustreNode', '');

        obj.localContract = localContract{1};
    else
        obj.localContract = localContract;
    end
end
