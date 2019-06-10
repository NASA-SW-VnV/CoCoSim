function OutOfBoundCheckCode(blk2LusObj, parent, blk, xml_trace, ...
        indexPortNames, width, isZeroBased, propID, propIndex)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculate Bound dimension
    if isZeroBased
        widthMin = nasa_toLustre.lustreAst.IntExpr(0);
        widthMax = nasa_toLustre.lustreAst.IntExpr(width-1);
    else
        widthMin = nasa_toLustre.lustreAst.IntExpr(1);
        widthMax = nasa_toLustre.lustreAst.IntExpr(width);
    end
    % set the property
    lines = cell(numel(indexPortNames), 1);
    for j=1:numel(indexPortNames)
        % widthMin <= index and index <= widthMax
        lines{j} = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.AND, ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.LTE, widthMin, indexPortNames{j}), ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.LTE, indexPortNames{j}, widthMax));
    end
    if ~isempty(lines)
        prop = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
            nasa_toLustre.lustreAst.BinaryExpr.AND, lines);
        blk2LusObj.addCode(nasa_toLustre.lustreAst.LocalPropertyExpr(propID, prop));
        % add traceability:
        parent_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent);
        xml_trace.add_Property(blk.Origin_path, ...
            parent_name, propID, propIndex, ...
            CoCoBackendType.DED_OUTOFBOUND);
    end
end

