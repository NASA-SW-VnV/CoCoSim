function htmlCmd = addOpenCmd(blk, shortName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin < 2
        shortName = HtmlItem.removeHtmlKeywords(blk);
    end
    htmlCmd = sprintf('<a href="matlab:open_and_hilite_hyperlink (''%s'',''error'')">%s</a>', ...
        regexprep(blk, '\n', ' '),shortName);
end
