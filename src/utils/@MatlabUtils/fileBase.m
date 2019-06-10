%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% for fileNames such as "test.LUSTREC.lus" it should returns "test"
function fname = fileBase(path)
    [~, fname, ~ ] = fileparts(path);
    if MatlabUtils.contains(fname, '.')
        fname = MatlabUtils.fileBase(fname);
    end
end
