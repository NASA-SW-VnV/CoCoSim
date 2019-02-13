%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% simplify expression
function all_obj = getAllLustreExpr(obj)
    all_obj = {};
    for i=1:numel(obj.bodyEqs)
        all_obj = [all_obj; {obj.bodyEqs{i}}; obj.bodyEqs{i}.getAllLustreExpr()];
    end
end
