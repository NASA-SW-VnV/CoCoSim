
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = changeVar(params, oldName, newName)
    
    for i=1:numel(params)
        if strcmp(params{i}.getId(), oldName)
            params{i} = nasa_toLustre.lustreAst.VarIdExpr(newName);
        end
    end
end
