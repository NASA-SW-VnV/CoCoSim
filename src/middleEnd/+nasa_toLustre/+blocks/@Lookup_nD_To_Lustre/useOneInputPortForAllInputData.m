
function inputs = useOneInputPortForAllInputData(blk,isLookupTableDynamic,inputs,NumberOfTableDimensions)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if ~isLookupTableDynamic
        p_inputs = {};
        if strcmp(blk.UseOneInputPortForAllInputData, 'on')
            dimLen = numel(inputs{1})/NumberOfTableDimensions;
            for i=1:NumberOfTableDimensions
                p_inputs{i} = inputs{1}((i-1)*dimLen+1:i*dimLen);
            end
            inputs = p_inputs;
        end
    end
end

