%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [instructionsIDs, inputList]= get_mcdc_instructions(initial_variables_names, ...
        lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables)
    instructionsIDs = {};
    inputList = {};
    new_variables_names = {};
    for i=1:numel(initial_variables_names)
        %add the current list instructions
        instructionsIDs{numel(instructionsIDs) + 1} = lhs_instrID_map(initial_variables_names{i});
        %caclulate the dependencies
        rhs_list = lhs_rhs_map(initial_variables_names{i});
        if iscell(rhs_list)
            for j=1:numel(rhs_list)
                origin_name = originalNamesMap(rhs_list{j});
                if ismember(origin_name, traceable_variables)
                    inputList{numel(inputList) + 1} = rhs_list{j};
                else
                    new_variables_names{numel(new_variables_names) + 1} = ...
                        rhs_list{j};
                end
            end
        else
            origin_name = originalNamesMap(rhs_list);
            if ismember(origin_name, traceable_variables)
                inputList{numel(inputList) + 1} = rhs_list;
            else
                new_variables_names{numel(new_variables_names) + 1} = ...
                    rhs_list;
            end
        end
    end
    if ~isempty(new_variables_names)
        [instructionsIDs_2, inputList_2]= MCDC2SLX.get_mcdc_instructions(new_variables_names, ...
            lhs_instrID_map, lhs_rhs_map, originalNamesMap, traceable_variables);
        instructionsIDs = [instructionsIDs, instructionsIDs_2];
        inputList = [inputList, inputList_2];
    end
    inputList = unique(inputList);
    instructionsIDs = unique(instructionsIDs);
end
