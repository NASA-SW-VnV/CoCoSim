function status = check_files_exist(varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

    status = 0;
    for i=1:numel(varargin)
        if ~exist(varargin{i}, 'file')
            msg = sprintf('FILE NOT FOUND: %s', varargin{i});
            display_msg(msg, Constants.ERROR, 'Zustre ', '');
            status = 1;
            break;
        end
    end
end


