%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function  diff1in2  = setdiff_struct( struct2, struct1, fieldname )
    %return the elements in struct2 that are not in struct1
    if isempty(struct2)
        diff1in2 = [];
    elseif isempty(struct1)
        diff1in2 = struct2;
    else
        AA = struct2(~cellfun(@isempty,{struct2.(fieldname)}));
        BB = struct1(~cellfun(@isempty,{struct1.(fieldname)}));
        A = {AA.(fieldname)} ;
        B = {BB.(fieldname)} ;
        [~,ia] = setdiff(A,B) ;
        diff1in2 = struct2(ia) ;
    end
end
