function res = isLastModified(old_file1, new_file2)
    % This function return true if file2 is new comparing to file1
    % This means file2 has been modified or created after file1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

    if ~exist(new_file2, 'file') || ~exist(old_file1, 'file')
        res = false;
        return;
    end
    f1_info = dir(old_file1);
    f2_info = dir(new_file2);
    if isempty(f1_info) || isempty(f2_info)
        res = false;
        return;
    end
    res = f1_info.datenum < f2_info.datenum;
end
