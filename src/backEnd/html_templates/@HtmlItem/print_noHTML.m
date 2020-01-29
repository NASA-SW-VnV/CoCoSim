function res = print_noHTML(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    lines{1} = obj.title;
    for i=1:numel(obj.subtitles)
        lines{end+1} = obj.subtitles{i}.print_noHTML();
    end
    res = MatlabUtils.strjoin(lines, '\n');
end
