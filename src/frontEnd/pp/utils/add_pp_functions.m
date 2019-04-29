function    add_pp_functions( files )
    %ADD_PP_FUNCTIONS Add matlab functions given by the user via pp_user_config
    %html page.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    global priority_pp_map;

    fcts_map = makeCopy(priority_pp_map);
    lowest_priority = max(cell2mat(fcts_map.values));

    if isempty(lowest_priority)
        lowest_priority = 0;
    end
    files_names = regexp(files, ', ', 'split');

    for i=1:numel(files_names)
       full_path = which(files_names{i});
       if strcmp(full_path, '')
           display_msg(sprintf('Function "%s" NOT FOUND in MATLAB PATH.', files_names{i}), ...
               MsgType.ERROR, 'add_pp_functions', '');
           continue;
       end
       fcts_map(full_path) = lowest_priority;
    end
    ordered_functions = PPConfigUtils.get_ordered_functions(fcts_map);
    pp_user_config(fcts_map, ordered_functions);
end

function map = makeCopy(orig)
    map = containers.Map('KeyType', orig.KeyType, 'ValueType', orig.ValueType);
    for k= orig.keys
        map(k{1}) = orig(k{1});
    end
end