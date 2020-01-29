%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function new_obj = deepCopy(obj)
    new_inputs = cellfun(@(x) x.deepCopy(), obj.inputs, 'UniformOutput', 0);
    new_outputs = cellfun(@(x) x.deepCopy(), obj.outputs, 'UniformOutput', 0);
    if isempty(obj.localContract)
        new_localContract = obj.localContract;
    else
        new_localContract = obj.localContract.deepCopy();
    end
    new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, 'UniformOutput', 0);
    new_bodyEqs = cellfun(@(x) x.deepCopy(), obj.bodyEqs, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name,...
        new_inputs, ...
        new_outputs, new_localContract, new_localVars, new_bodyEqs, ...
        obj.isMain, obj.isImported);
end
