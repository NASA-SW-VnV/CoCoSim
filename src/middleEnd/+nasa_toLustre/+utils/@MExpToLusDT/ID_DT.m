function [lusDT, slxDT] = ID_DT(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    data_map = args.data_map;
    inputs = args.inputs;
    isSimulink = args.isSimulink;
    
    if ischar(tree)
        id = tree;
    else
        id = tree.name;
    end
    % the case of final term in a tree
    if strcmp(id, 'true') || strcmp(id, 'false')
        lusDT = 'bool';
        slxDT = 'boolean';
    elseif isSimulink && strcmp(id, 'u')
        %the case of u with no index in IF/Fcn/SwitchCase blocks
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, inputs{1}{1}.getId());
        
    elseif isSimulink && ~isempty(regexp(id, 'u\d+', 'match'))
        %the case of u1, u2 in IF/Fcn/SwitchCase blocks
        input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
            inputs{str2double(input_idx)}{1}.getId());
        
    else
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, id);
    end

end
