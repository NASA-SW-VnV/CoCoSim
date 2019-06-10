function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_obj = obj.deepCopy();
    if ~isempty(outputs_map) && isKey(outputs_map, obj.getId())
        occ = outputs_map(obj.getId());
        if isLeft
            %increase number of occurance
            occ = occ + 1;
        end
        if occ > 0
            new_obj.setId(strcat(obj.getId(), '__', num2str(occ)));
            outputs_map(obj.getId()) = occ;
        end
    end
end
