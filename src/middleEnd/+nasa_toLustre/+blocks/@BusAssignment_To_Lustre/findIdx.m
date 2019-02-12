
function idx = findIdx(VarIds, var)
    varNames = cellfun(@(x) x.getId(), VarIds, 'UniformOutput', 0);
    varName = var.getId();
    idx = strcmp(varNames, varName);
end

