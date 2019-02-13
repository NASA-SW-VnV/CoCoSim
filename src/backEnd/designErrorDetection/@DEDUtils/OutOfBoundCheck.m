function prop = OutOfBoundCheck(indexPortNames, width)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    prop = {};
    % calculate Bound dimension
    widthMin = IntExpr(1);
    widthMax = IntExpr(width);
    % set the property
    lines = cell(numel(indexPortNames), 1);
    for j=1:numel(indexPortNames)
        % widthMin <= index and index <= widthMax
        lines{j} = BinaryExpr(BinaryExpr.AND, ...
            BinaryExpr(BinaryExpr.LTE, widthMin, indexPortNames{j}), ...
            BinaryExpr(BinaryExpr.LTE, indexPortNames{j}, widthMax));
    end
    if ~isempty(lines)
        prop = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, lines);
    end
end

