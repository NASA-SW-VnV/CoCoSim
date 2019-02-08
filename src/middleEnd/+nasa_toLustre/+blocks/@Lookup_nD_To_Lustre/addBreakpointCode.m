
function [body,vars,Breakpoints] = ...
        addBreakpointCode(BreakpointsForDimension,blk_name,...
        lusInport_dt,isLookupTableDynamic,inputs,NumberOfTableDimensions)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % This function define the breakpoints defined by
    % users.
    body = {};
    vars = {};            
    for j = 1:NumberOfTableDimensions
        Breakpoints{j} = {};
        for i=1:numel(BreakpointsForDimension{j})
            Breakpoints{j}{i} = VarIdExpr(...
                sprintf('%s_Breakpoints_dim%d_%d',blk_name,j,i));
            %vars = sprintf('%s\t%s:%s;\n',vars,Breakpoints{j}{i},lusInport_dt);
            vars{end+1} = LustreVar(Breakpoints{j}{i},lusInport_dt);
            if ~isLookupTableDynamic
                %body = sprintf('%s\t%s = %.15f ;\n', body, Breakpoints{j}{i}, BreakpointsForDimension{j}(i));
                body{end+1} = LustreEq(Breakpoints{j}{i}, RealExpr(BreakpointsForDimension{j}(i)));
            else
                %body = sprintf('%s\t%s = %s;\n', body, Breakpoints{j}{i}, inputs{2}{i});
                body{end+1} = LustreEq(Breakpoints{j}{i}, inputs{2}{i});
            end

        end
    end
end
