function [body,vars,table_elem] = addTableCode(blkParams,...
        node_header)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function defines the blkParams.Table values defined by users.
    
    
    numBoundNodes = 2^blkParams.NumberOfTableDimensions;
    if nasa_toLustre.utils.LookupType.isLookupDynamic(blkParams.lookupTableType)
        numberTableData = blkParams.numberTableData;
    else
        numberTableData = numel(blkParams.Table);
    end
    table_elem = cell(1, numberTableData);
    body = cell(1, numel(numberTableData));
    vars = cell(1, numel(numberTableData));
    for i=1:numberTableData
        table_elem{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('ydat_%d',i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            table_elem{i},'real');
        if ~(nasa_toLustre.utils.LookupType.isLookupDynamic(blkParams.lookupTableType))
            body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, ...
                nasa_toLustre.lustreAst.RealExpr(blkParams.Table(i)));
        else
            if blkParams.directLookup
                body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, ...
                    node_header.inputs_name{1+i});
            else
                body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, ...
                    node_header.inputs_name{2*numBoundNodes+i});
            end
        end
    end
    
    
end
