function [params] = matlabFunction_dotTest()
    fun_name = 'dot';
    % properties that will participate in permutations
    inputDataType = {'double', 'single'};
    inputDimension = {'1', '[3,1]', '[1,3]', '[2,3]'};
    oneInputFcn = { ...
        sprintf('y = %s(u, v);', fun_name)};
    
    header = 'function y = fcn(u, v)';
    params = {};
    pInType = 0;
    for funcIdx = 1 : length(oneInputFcn)
        for inDim_idx = 1 : length(inputDimension)
            pInType = mod(pInType, length(inputDataType)) + 1;
            s = struct();
            s.Script = sprintf('%s\n%s', header, oneInputFcn{funcIdx});
            s.nbInputs = 2;
            s.inDT{1} = inputDataType{pInType};
            s.inDT{2} = inputDataType{pInType};
            s.inDim{1} = inputDimension{inDim_idx};
            s.inDim{2} = inputDimension{inDim_idx};
            params{end+1} = s;
        end
    end
end

