function [results, passed, priority] = ar_0001(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % ar_0001: Filenames
    priority = 1; %Mandatory
    results = {};
    passed = 1;
    totalFail = 0;
    
    [~,name,ext] = fileparts(which(model));
    
    %% NAME %%
    % name no leading digits
    title = 'name no leading digits';
    if(isempty(regexp(name,'^\d', 'once')))
        failedList = {};
    else
        failedList = {name};
    end
    [leading_number_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;     
    
    % name no blanks
    title = 'no blanks in name';
    if(isempty(regexp(name,'^\d', 'once')))
        failedList = {};
    else
        failedList = {name};
    end   
    [no_space_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;      
    
    % allowableCharactersInName
    title = 'name allowable characters: [a-zA-Z_0-9]';    
    if(isempty(regexp(name,'\W', 'once')))
        failedList = {};
    else
        failedList = {name};
    end     
    [allowableCharactersInName, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;     
    
    % cannot have more than one consecutive underscore
    title = 'cannot have more than one consecutive underscore';    
    if(isempty(regexp(name,'__', 'once')))
        failedList = {};
    else
        failedList = {name};
    end    
    [consecutive_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;    
    
    % cannot start with an underscore
    title = 'name cannot start with an underscore';
    if(isempty(regexp(name,'^_', 'once')))
        failedList = {};
    else
        failedList = {name};
    end         
    [starts_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;

    % cannot end with an underscore
    title = 'cannot end with an underscore';
    if(isempty(regexp(name,'_$', 'once')))
        failedList = {};
    else
        failedList = {name};
    end     
    [ends_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;    
    
    %% EXT %%  
    
    % ext no blanks
    title = 'no blanks in ext';
    if(isempty(regexp(ext,'\s', 'once')))
        failedList = {};
    else
        failedList = {ext};
    end   
    [no_space_in_ext, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;      
    
    
    % allowableCharactersInext
    title = 'ext allowable characters: [a-zA-Z0-9]';
    % remove 1st dot in ext
    ext_less_1st_char = ext(2:end);
    if(isempty(regexp(ext_less_1st_char,'\W', 'once')))
        failedList = {};
    else
        failedList = {ext};
    end
    
    [allowableCharactersInext, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;     
    
    % no underscore in ext
    title = 'no underscore in ext';    
    if(isempty(regexp(ext,'_', 'once')))
        failedList = {};
    else
        failedList = {ext};
    end    
    [no_underscore, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;      
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
        
    %the main guideline
    title = 'ar_0001: Filenames';
    description_text = 'A filename conforms to the following:';
    %description_text = ['A filename conforms to the following:<br>'...
    %    'another texdjglrkjgrve<br>' ...
    %    'egtehgrhtrht'];
    % version 1: small description
    description = HtmlItem(description_text, {}, 'black', 'black');
    % version 2: big description 
%     description = HtmlItem('Description', ...
%         {HtmlItem(description_text, {}, 'black', 'black')},...
%         'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        leading_number_in_name,...
        no_space_in_name,...
        allowableCharactersInName,...
        consecutive_underscore_in_name,...
        starts_with_underscore_in_name,...
        ends_with_underscore_in_name,...
        no_space_in_ext,...
        allowableCharactersInext,...
        no_underscore,...
        }, color, color);
end

