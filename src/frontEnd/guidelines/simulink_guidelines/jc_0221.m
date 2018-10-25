function [results, passed] = jc_0221(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0221: Usable characters for signal line names
    % name: 
         
    results = {};
    title = 'jc_0221: Usable characters for signal line names';
    passed = 1;
    totalFail = 0;
    oldLines = [];
    
    [no_space_in_name, numFail,oldLines] = ...
        check_no_space_in_name(model,oldLines);
    totalFail = totalFail + numFail;
    
%     [leading_number_in_name, numFail,oldLines] = ...
%         check_leading_number_in_name(model,oldLines);
%     totalFail = totalFail + numFail;
%     
%     [no_carriage_return_in_name, numFail,oldLines] =  ...
%         check_no_carriage_return_in_name(model,oldLines);
%     totalFail = totalFail + numFail;
%     
%     [consecutive_underscore_in_name, numFail,oldLines] = ...
%         check_consecutive_underscore_in_name(model,oldLines);
%     totalFail = totalFail + numFail;
%     
%     [starts_with_underscore_in_name, numFail,oldLines] = ...
%         check_starts_with_underscore_in_name(model,oldLines);
%     totalFail = totalFail + numFail;
%     
%     [ends_with_underscore_in_name, numFail,oldLines] = ...
%         check_ends_with_underscore_in_name(model,oldLines);
%     totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
    end

%     results{end+1} = HtmlItem(title, {no_space_in_name,...
%         leading_number_in_name,no_carriage_return_in_name,...
%         consecutive_underscore_in_name, starts_with_underscore_in_name,...
%         ends_with_underscore_in_name},'black');

    results{end+1} = HtmlItem(title, {no_space_in_name},'black');

end


function [results, numFail, oldLines] = check_no_space_in_name(model,oldLines)
    blks = find_system(model);
    failList = {};
    % following 2 lines do not work
    inputSignalNames = find_system(model,'Regexp', 'on','InputSignalNames','\w*');
    outputSignalNames = find_system(model,'Regexp', 'on','OutputSignalNames','\w*');
    for i=1:length(blks)
        try
            p = get_param(blks{i},'PortHandles');
        catch
            continue;     % no PortHandles
        end

        % Inport
        for j=1:length(p.Inport)
            handle = p.Inport(j);
            l = get_param(p.Inport,'Line');
            if ismember(l,oldLines)
                continue;
            else
                oldLines = [oldLines,l];
            end
            
            failName = get_param(l,'Name');   
            if ~isempty(failName)
                if regexp(failName,'\s')
                    failList{end+1} = sprintf('block: %s, signal: %s',blks{i},get_param(l,'Name'));    
                end
            end
        end        
        % Outport        
        for j=1:length(p.Outport)
            handle = p.Outport(j);
            l = get_param(p.Outport,'Line');
            if ismember(l,oldLines)
                continue;
            else
                oldLines = [oldLines,l];
            end
            
            failName = get_param(l,'Name');   
            if ~isempty(failName)
                if regexp(failName,'\s')
                    failList{end+1} = sprintf('block: %s, signal: %s',blks{i},get_param(l,'Name'));    
                end
            end
        end        
        % Enable
        % Trigger
        % State
        % LConn
        % RConn
        % Ifaction
        % Reset
        
    end
    [results, numFail] = ...
        process_find_system_results(...
        failList,...  
        'should not have blank spaces');
end

function [results, numFail,oldLines] = check_leading_number_in_name(model,oldLines)
    [results, numFail,oldLines] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','^\d'),...  
        'should not start with a number');
end

function [results, numFail,oldLines] = check_no_carriage_return_in_name(model,oldLines)
    [results, numFail,oldLines] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\n'),...  
        'carriage returns are not allowed');
end

function [results, numFail,oldLines] = check_consecutive_underscore_in_name(model,oldLines)
    [results, numFail,oldLines] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','__'),...  
        'cannot have more than one consecutive underscore');
end

function [results, numFail,oldLines] = check_starts_with_underscore_in_name(model,oldLines)
    [results, numFail,oldLines] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','^_'),...  
        'cannot start with an underscore');
end

function [results, numFail,oldLines] = check_ends_with_underscore_in_name(model,oldLines)
    [results, numFail,oldLines] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','_$'),...  
        'cannot end with an underscore');
end

function [results, numFail] = process_find_system_results(fsList,title)
    numFail = 0;
    failList = cell(1,length(fsList));
    if isempty(fsList)
        failList{1} =  HtmlItem('PASS',{},'green');
    else
        for i=1:length(fsList)
            failList{i} =  HtmlItem(fsList{i},{},'red');
            numFail = 1 + numFail;
        end
    end
    results = HtmlItem(title,failList,'blue');
end



