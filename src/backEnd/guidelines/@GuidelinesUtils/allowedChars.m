function allowedCharList = allowedChars(model,options)
    % This function aided in the searching for allowable characters common in
    % guidelines for names in various Simulink objects.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fsString = 'find_system(model, ''Regexp'', ''on''';
    for i=1:length(options)
        fsString = sprintf('%s, ''%s''',fsString, options{i});
    end
    fsString = sprintf('%s, ''Name'', ''\\W'');',fsString);
    fsList1 =  eval(fsString);
    %             fsList1 =  find_system(model, 'Regexp', 'on','FindAll','on',...
    %                 typeList{1},typeList{2}, 'Name', '\W');
    fsString = 'find_system(model, ''Regexp'', ''on''';
    for i=1:length(options)
        fsString = sprintf('%s, ''%s''',fsString, options{i});
    end
    fsString = sprintf('%s, ''Name'', ''^<\\w+>$'');',fsString);
    fsList2 =  eval(fsString);
    %             fsList2 = find_system(model, 'Regexp', 'on','FindAll','on',...
    %                 'type','line', 'Name', '^<\w+>$');
    allowedCharList = setdiff(fsList1, fsList2);
end
        


