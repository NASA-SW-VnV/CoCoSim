function [params] = matlabFunction_cumsumTest()
    fun_name = 'cumsum';
    % properties that will participate in permutations
    inputDataType = {'double','single','int8', 'uint8','int32','uint32', 'boolean'};
    inputDimension = {'1', '[3,1]', '[1,3]', '[2,3]', '[2 3 4]'};
    oneInputFcn = { ...
        sprintf('y = %s(u);', fun_name),...
        sprintf('y = %s(u, 1);', fun_name),...
        sprintf('y = %s(u, 2);', fun_name), ...
        sprintf('y = %s(u, 1, ''reverse'');', fun_name), ...
        sprintf('y = %s(u, 2, ''reverse'');', fun_name),};
    
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

