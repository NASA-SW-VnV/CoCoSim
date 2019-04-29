function metaInfo = getModelInfo(title, model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tableItemFormat = '<tr><td align="left">%s:</td><td align="left">%s</td></tr>';
    tableElts = {};

    % add model Name
    tableElts{end+1} = sprintf(tableItemFormat, ...
        'Model Path',...
        get_param(model, 'filename'));

    % add title
    tableElts{end+1} = sprintf(tableItemFormat, ...
        'Mode',...
        title);

    % add time
    tableElts{end+1} = sprintf(tableItemFormat, ...
        'Time Stamp',...
        datestr(now));

    metaInfo = MatlabUtils.strjoin(tableElts, '\n');
end

