function [results, passed] = bn_0002(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % bn_0002: Signal name length limit

    results = {};
    title = 'bn_0002: Signal name length limit';
    
    signalList = ppList(...
        find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line'));    
    
    [results{1}, ~] = ...
        GuidelinesUtils.process_find_system_results(signalList,title,...
        false, false); 
    passed = isempty(signalList);

end


function newList = ppList(list)
    %remove empty lines
    Names = arrayfun(@(x) get_param(x, 'Name'), list, 'UniformOutput',...
        false);
    %list = list(~strcmp(Names, '')&&);
    % lind name length less than 5
    list = list(length(Names)>5);
    %add parent
    newList = arrayfun(@(x) ...
        sprintf('%s in %s', ...
        HtmlItem.cleanTitle(get_param(x, 'Name')), ...
        HtmlItem.addOpenCmd(get_param(x, 'Parent'))), ...
        list, 'UniformOutput', false);
end