
function [body,vars,table_elem] = ...
        addTableCode(Table,blk_name,lusInport_dt,isLookupTableDynamic,inputs)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % This function defines the table values defined by users.
    table_elem = cell(1, numel(Table));
    body = cell(1, numel(Table));
    vars = cell(1, numel(Table));
    for i=1:numel(Table)
        table_elem{i} = VarIdExpr(...
            sprintf('%s_table_elem_%d',blk_name,i));
        vars{i} = LustreVar(table_elem{i},lusInport_dt);
        if ~isLookupTableDynamic
            body{i} = LustreEq(table_elem{i}, RealExpr(Table(i)));
        else
            body{i} = LustreEq(table_elem{i}, inputs{3}{i});
        end


    end
end
