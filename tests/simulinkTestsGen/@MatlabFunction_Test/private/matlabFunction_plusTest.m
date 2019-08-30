function [params] = matlabFunction_plusTest()
    fun_name = 'plus';
    % properties that will participate in permutations
    inputDataType = {'double','single','int8', 'uint8','int32','uint32', 'boolean'};
    inputDimension = {'1', '[3,1]', '[1,3]', '[2,3]'};
    oneInputFcn = { ...
        sprintf('y = %s(u, v);', fun_name),};
    
    header = 'function y = fcn(u, v)';
    params = {};
    pInType_1 = 0;
    pInType_2 = 1;
    for funcIdx = 1 : length(oneInputFcn)
        for inDim_idx = 1 : length(inputDimension)
            pInType_1 = mod(pInType_1, length(inputDataType)) + 1;
            pInType_2 = mod(pInType_2, length(inputDataType)) + 1;
            s = struct();
            s.Script = sprintf('%s\n%s', header, oneInputFcn{funcIdx});
            s.nbInputs = 2;
            s.inDT{1} = inputDataType{pInType_1};
            s.inDT{2} = inputDataType{pInType_2};
            s.inDim{1} = inputDimension{inDim_idx};
            s.inDim{2} = inputDimension{inDim_idx};
            params{end+1} = s;
        end
    end
end

