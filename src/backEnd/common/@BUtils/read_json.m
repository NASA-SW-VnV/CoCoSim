function data = read_json(contract_path)
    % read json file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    try
        filetext = fileread(contract_path);
    catch ME
        display_msg(['Could not read file ' contract_path], Constants.ERROR, 'read_json', '');
        rethrow(ME);
    end

    % encode json file
    filetext = regexprep(filetext,'"__','"xx');

    %parse the data
    if strcmp(filetext, '')
        warndlg('No cocospec contracts were generated','CoCoSim: Warning');
        return;
    end
    try
        data = MatlabUtils.jsondecode(filetext);
    catch ME
        display_msg(['Could not read file ' contract_path], Constants.ERROR, 'read_json', '');
        rethrow(ME);
    end
end

