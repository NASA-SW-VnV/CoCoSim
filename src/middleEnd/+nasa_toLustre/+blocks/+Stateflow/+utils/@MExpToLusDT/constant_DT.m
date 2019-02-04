function dt = constant_DT(tree, varargin)
    if isequal(tree.dataType, 'Integer')
        dt = 'int';
    elseif isequal(tree.dataType, 'Float')
        dt = 'real';
    else
        dt = '';
    end
end