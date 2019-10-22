function [params] = matlabFunction_normTest()
    fun_name = 'norm';
    % properties that will participate in permutations
    inputDataType = {'double','single'};
    inputDimension = {'1', '[3,1]', '[1,3]', '[2,3]'};
    oneInputFcn = { ...
        sprintf('y = %s(u);', fun_name),...
        sprintf('y = %s(u, 1);', fun_name),...
        sprintf('y = %s(u, 2);', fun_name), ...
        sprintf('y = %s(u, ''fro'');', fun_name)};
    
    header = 'function y = fcn(u)';
    params = {};
    pInType = 0;
    for funcIdx = 1 : length(oneInputFcn)
        for inDim_idx = 1 : length(inputDimension)
            if funcIdx == 4 && inDim_idx < 4 
                % 'y = norm(u, ''fro'');' =>  dim = '[2 3]'
                continue;
            end
            if funcIdx < 4 && inDim_idx == 4 
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

