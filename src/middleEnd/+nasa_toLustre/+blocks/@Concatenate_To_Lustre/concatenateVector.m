
        
function [codes] = concatenateVector(nb_inputs, inputs, outputs)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    codes = cell(1, numel(outputs));
    outputIndex = 0;
    for i=1:nb_inputs
        for j=1:numel(inputs{i})
            outputIndex = outputIndex + 1;
            codes{outputIndex} = LustreEq(outputs{outputIndex}, inputs{i}{j});
        end
    end
end
        

