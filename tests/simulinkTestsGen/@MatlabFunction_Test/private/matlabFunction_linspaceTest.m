function [params] = matlabFunction_linspaceTest()
    fun_name = 'linspace';
    % properties that will participate in permutations
    inputDataType = {'double'};
    inputDimension = {'1'};
    oneInputFcn = { ...
        sprintf('y = %s(1, 5);', fun_name), ...
        sprintf('y = %s(1, 5, 50);', fun_name)};
    
    header = 'function y = fcn(u)';
    params = {};
    for funcIdx = 1 : length(oneInputFcn)
        s = struct();
        s.Script = sprintf('%s\n%s', header, oneInputFcn{funcIdx});
        s.nbInputs = 1;
        s.inDT{1} = inputDataType{1};
        s.inDim{1} = inputDimension{1};
        params{end+1} = s;
    end
end
