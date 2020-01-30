function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    new_rhs = obj.rhs.pseudoCode2Lustre(outputs_map, false, node, data_map);
    [new_lhs, outputs_map] = obj.lhs.pseudoCode2Lustre(outputs_map, true, node, data_map);
    new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
end
