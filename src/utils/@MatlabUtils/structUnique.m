%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function res = structUnique(struct2, fieldname)

    res = struct2;
    if isempty(struct2)
        return;
    end
    if iscell(struct2)
        A = cellfun(@(x) {x.(fieldname)},struct2);
    else
        AA = struct2(~cellfun(@isempty,{struct2.(fieldname)}));
        A = {AA.(fieldname)};
    end
    [~,ia] = unique(A) ;
    res = struct2(ia) ;
end
        
