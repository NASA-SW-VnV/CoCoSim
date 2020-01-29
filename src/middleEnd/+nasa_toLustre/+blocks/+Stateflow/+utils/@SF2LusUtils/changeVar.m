
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function params = changeVar(params, oldName, newName)
    
    for i=1:numel(params)
        if strcmp(params{i}.getId(), oldName)
            params{i} = nasa_toLustre.lustreAst.VarIdExpr(newName);
        end
    end
end
