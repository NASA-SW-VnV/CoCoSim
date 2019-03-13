function newList = ppSignalNames(list)
    % get names from handles
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    Names = arrayfun(@(x) get_param(x, 'Name'), list, 'UniformOutput',...
        false);
    %remove empty lines
    list = list(~strcmp(Names, ''));
    %add parent
    newList = arrayfun(@(x) ...
        sprintf('%s in %s', ...
        HtmlItem.removeHtmlKeywords(get_param(x, 'Name')), ...
        HtmlItem.addOpenCmd(get_param(x, 'Parent'))), ...
        list, 'UniformOutput', false);
end


