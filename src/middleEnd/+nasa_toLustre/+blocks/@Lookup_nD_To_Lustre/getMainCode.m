
function codes = getMainCode(outputs,inputs,ext_node_name,...
        isLookupTableDynamic,output_conv_format)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    codes = cell(1, numel(outputs));
    for outIdx=1:numel(outputs)
        nodeCall_inputs = {};
        if isLookupTableDynamic
            nodeCall_inputs{end+1} = inputs{1}{outIdx};
            for i=2:numel(inputs)
                nodeCall_inputs = [nodeCall_inputs, inputs{i}];
            end
        else
            nodeCall_inputs = cell(1, numel(inputs));
            for i=1:numel(inputs)
                nodeCall_inputs{i} = inputs{i}{outIdx};
            end
        end

        if isempty(output_conv_format)
            codes{outIdx} = LustreEq(outputs{outIdx}, ...
                NodeCallExpr(ext_node_name, nodeCall_inputs));
        else
            code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(output_conv_format, ...
                NodeCallExpr(ext_node_name, nodeCall_inputs));
            codes{outIdx} = LustreEq(outputs{outIdx}, code);                    
        end
    end
end
