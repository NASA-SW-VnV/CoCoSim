function new_obj = simplify(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    new_inputs = cellfun(@(x) x.simplify(), obj.inputs, 'UniformOutput', 0);
    new_outputs = cellfun(@(x) x.simplify(), obj.outputs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractImportExpr(obj.name, ...
        new_inputs, new_outputs);
end
