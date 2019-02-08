
function ExecutionCondName = getExecutionCondName(blk)
    import nasa_toLustre.utils.SLX2LusUtils
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    ExecutionCondName = sprintf('ExecutionCond_of_%s', blk_name);
end
