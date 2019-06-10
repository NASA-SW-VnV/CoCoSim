function new_obj = simplify(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    new_requires = cellfun(@(x) x.simplify(), obj.requires, ...
        'UniformOutput', 0);
    new_ensures = cellfun(@(x) x.simplify(), obj.ensures, ...
        'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractModeExpr(obj.name, new_requires, new_ensures);
end
