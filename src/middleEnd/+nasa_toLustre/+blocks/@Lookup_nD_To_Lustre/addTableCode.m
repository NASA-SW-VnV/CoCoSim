function [body,vars,table_elem] = ...
        addTableCode(Table,blk_name,lusInport_dt,isLookupTableDynamic,inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % This function defines the table values defined by users.
    table_elem = cell(1, numel(Table));
    body = cell(1, numel(Table));
    vars = cell(1, numel(Table));
    for i=1:numel(Table)
        table_elem{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('%s_table_elem_%d',blk_name,i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(table_elem{i},lusInport_dt);
        if ~isLookupTableDynamic
            body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, nasa_toLustre.lustreAst.RealExpr(Table(i)));
        else
            body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, inputs{3}{i});
        end


    end
end
