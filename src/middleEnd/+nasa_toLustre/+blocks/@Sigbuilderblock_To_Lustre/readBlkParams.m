
function blkParams = readBlkParams(blk)
    import nasa_toLustre.utils.SLX2LusUtils
    blkParams = struct;
    blkParams.OutputAfterFinalValue = blk.Content.FromWs.OutputAfterFinalValue;
    blkParams.blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
end
