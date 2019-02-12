
function [new_inputs, invertCodes, AdditionalVars] = invertInputs(obj, exp, inputs, blk, LusOutputDataTypeStr)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    blk_id = sprintf('%.3f', blk.Handle);
    blk_id = strrep(blk_id, '.', '_');
    new_inputs = {};
    invertCodes = {};
    AdditionalVars = {};
    for i=1:numel(exp)
        if isequal(exp(i), '/')
            %create new variables
            for j=1:numel(inputs{i})
                if iscell(inputs{i}{j})
                    v = inputs{i}{j}{1};
                else
                    v = inputs{i}{j};
                end
                v = VarIdExpr(...
                    strcat(v.getId(), '_inv_', blk_id));
                new_inputs{i}{j} = v;
                AdditionalVars{end+1} = LustreVar(v, LusOutputDataTypeStr);
            end
            n = sqrt(numel(inputs{i}));
            lib_name = sprintf('_inv_M_%dx%d', n, n);
            obj.addExternal_libraries(strcat('LustMathLib_', lib_name));
            invertCodes{end + 1} = LustreEq(new_inputs{i},...
                    NodeCallExpr(lib_name, inputs{i}));
            %create the equation B_inv= inv_x(B)
            %add the new variables to new_inputs
        else
            new_inputs{i} = inputs{i};
        end
    end
end
