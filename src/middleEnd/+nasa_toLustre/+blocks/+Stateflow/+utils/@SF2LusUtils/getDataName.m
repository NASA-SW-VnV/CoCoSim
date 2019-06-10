function names = getDataName(d)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    names = {};
    if isfield(d, 'CompiledSize')
        CompiledSize = str2num(d.CompiledSize);
    elseif isfield(d, 'ArraySize')
        CompiledSize = str2num(d.ArraySize);
    else
        CompiledSize = 1;
    end
    CompiledSize = prod(CompiledSize);
    if CompiledSize == 1 || CompiledSize == -1
        names = {d.Name};
    else
        for i=1:CompiledSize
            if isfield(d,'Id')
                %Stateflow case
                names{i} = sprintf('%s__ID%.0f_Index%d', d.Name, d.Id, i);
            else
                %Matlab case
                names{i} = sprintf('%s__Index%d', d.Name, i);
            end
        end
    end
end
