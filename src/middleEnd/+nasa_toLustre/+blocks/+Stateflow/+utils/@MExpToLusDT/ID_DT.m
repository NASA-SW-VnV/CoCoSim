function dt = ID_DT(tree, data_map, inputs, isSimulink, varargin)
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    if ischar(tree)
        id = tree;
    else
        id = tree.name;
    end
    % the case of final term in a tree
    if strcmp(id, 'true') || strcmp(id, 'false')
        dt = 'bool';
        
    elseif isSimulink && strcmp(id, 'u')
        %the case of u with no index in IF/Fcn/SwitchCase blocks
        dt = MExpToLusDT.getVarDT(data_map, inputs{1}{1}.getId());
        
    elseif isSimulink && ~isempty(regexp(id, 'u\d+', 'match'))
        %the case of u1, u2 in IF/Fcn/SwitchCase blocks
        input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
        dt = MExpToLusDT.getVarDT(data_map, ...
            inputs{str2double(input_idx)}{1}.getId());
        
    elseif isKey(data_map, id)
        if isfield(data_map(id), 'LusDatatype')
            dt = data_map(id).LusDatatype;
        else
            dt = data_map(id);
        end
    else
        dt = '';
    end
end