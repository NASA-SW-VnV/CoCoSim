function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if obj.islocalContract
        %Only import contracts are supported for the moment.
        for i=1:numel(obj.bodyEqs)
            if isa(obj.bodyEqs{i}, 'nasa_toLustre.lustreAst.ContractImportExpr')
                [obj.bodyEqs{i}, outputs_map] = ...
                    obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map);
            end
        end
        new_obj = obj;
    else
        %it is not used by stateflow.
        new_obj = obj;
    end
end
