%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_obj = simplify(obj)
    %TODO change it to object function. no need for new_obj
    new_obj = obj.substituteVars();
    if ~isempty(obj.localContract)
        new_obj.setLocalContract(new_obj.localContract.simplify());
    end
    new_obj.setBodyEqs(...
        cellfun(@(x) x.simplify(), new_obj.bodyEqs, 'UniformOutput', 0));

end
