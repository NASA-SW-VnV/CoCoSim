function [params] = matlabFunction_eyeTest()
    fun_name = 'eye';
    % properties that will participate in permutations
    inputDataType = {'single'};
    inputDimension = {'1'};
    oneInputFcn = { ...
        sprintf('y = %s(1);', fun_name), ...
        sprintf('y = %s(3);', fun_name), ...
        sprintf('y = %s(3, 4);', fun_name), ...
        sprintf('y = %s([3, 4]);', fun_name)};
    
    header = 'function y = fcn(u)';
    params = {};
    pInType = 0;
    for funcIdx = 1 : length(oneInputFcn)
        for inDim_idx = 1 : length(inputDimension)
            pInType = mod(pInType, length(inputDataType)) + 1;
            s = struct();
            s.Script = sprintf('%s\n%s', header, oneInputFcn{funcIdx});
            s.nbInputs = 1;
            s.inDT{1} = inputDataType{pInType};
            s.inDim{1} = inputDimension{inDim_idx};
            params{end+1} = s;
        end
    end
end

