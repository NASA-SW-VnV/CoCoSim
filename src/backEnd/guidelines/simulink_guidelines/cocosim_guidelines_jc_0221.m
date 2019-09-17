function [results, passed, priority] = cocosim_guidelines_jc_0221(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0221: Usable characters for signal line names
    % h_0040: Usable characters for Simulink Bus Names
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    item_titles = {...
        'Should not start with a number or underscore', ...
        'should not have blank spaces', ...
        'carriage returns are not allowed', ...
        'Allowed Characters are [a-zA-Z_0-9]', ...
        'cannot have more than one consecutive underscore', ...
        'cannot start with an underscore', ...
        'cannot end with an underscore' ...
        };
    
    regexp_str = {...
        '^\d',...
        '\s',...
        '[\r\n]',...
        'custom',...    % handle i=4 differently
        '__',...
        '^_',...
        '_$'...
        };
        
    subtitles = cell(length(item_titles)+1, 1);
    for i=1:length(item_titles)
        item_title = item_titles{i};
        if i==4
            failedList = ...
                GuidelinesUtils.allowedChars(model,{'FindAll','on','type','line'});
            fsList = GuidelinesUtils.ppSignalNames(failedList);             
        else
            fsList = GuidelinesUtils.ppSignalNames(find_system(model,...
                'Regexp', 'on', 'FindAll','on',...
                'type','line', 'Name',regexp_str{i}));
        end
        [subtitles{i+1}, numFail] = ...
            GuidelinesUtils.process_find_system_results(fsList,item_title,...
            false);
        totalFail = totalFail + numFail;
    end    
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
        
    %the main guideline
    title = 'jc_0221: Usable characters for signal line names';
    description_text = ...
        'All Simulink Bus names should conform to the following constraints:';
    description = HtmlItem(description_text, {}, 'black', 'black');   
    subtitles{1} = description;
    results{end+1} = HtmlItem(title, subtitles, color, color);

end
