function new_obj = simplify(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    new_inputs = cellfun(@(x) x.simplify(), obj.inputs, 'UniformOutput', 0);
    new_outputs = cellfun(@(x) x.simplify(), obj.outputs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ContractImportExpr(obj.name, ...
        new_inputs, new_outputs);
end
