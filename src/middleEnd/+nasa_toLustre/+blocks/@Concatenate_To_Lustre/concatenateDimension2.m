
function [codes] = concatenateDimension2(inputs, outputs,in_matrix_dimension)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    codes = cell(1, numel(outputs));
    index = 0;
    for i=1:numel(in_matrix_dimension)       %loop over number of inports
        for j=1:numel(inputs{i})     % loop over each element of inport
            index = index + 1;
            codes{index} = LustreEq(outputs{index}, inputs{i}{j});
        end
    end
end

