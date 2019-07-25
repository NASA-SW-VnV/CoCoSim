function [params] = matlabFunction_allTest()
    % properties that will participate in permutations
    inputDataType = {'double','single','int8', 'uint8','int32','uint32', 'boolean'};
    inputDimension = {'1', '[3,1]', '[1,3]', '[2,3]', '[2 3 4]'};
    oneInputFcn = { ...
        'y = all(u);',...
        'y = all(u, 1);',...
        'y = all(u, 2);', ...
        'y = all(u, 3);'};
    
    header = 'function y = fcn(u)';
    params = {};
    pInType = 0;
    for funcIdx = 1 : length(oneInputFcn)
        for inDim_idx = 1 : length(inputDimension)
            if funcIdx == 4 && inDim_idx < 5
                % 'y = all(u, 3);' =>  dim = '[2 3 4]'
                continue;
            end
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

