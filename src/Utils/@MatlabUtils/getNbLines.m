%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function count = getNbLines(file)
    try
        fid = fopen(file);
        count = 0;
        while true
            if ~ischar( fgetl(fid) ); break; end
            count = count + 1;
        end
        fclose(fid);
        fprintf('lines in file %s is %d\n', file, count);
    catch
        count = -1;
    end
end


