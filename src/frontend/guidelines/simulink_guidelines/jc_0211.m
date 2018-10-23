function [results, passed] = jc_0211(model)
    %4.3.4.1 jc_0211: Usable characters for Inport block and Outport block
    results = {};
    title = '4.3.4.1 jc_0211: Usable characters for Inport block and Outport block';
    passed = 1;
    totalFail = 0;    
    blocks = find_system(model);
    
    [no_space_in_name, numFail] = ...
        check_no_space_in_name(model,blocks);
    totalFail = totalFail + numFail;
    
    [leading_number_in_name, numFail] = ...
        check_leading_number_in_name(model,blocks);
    totalFail = totalFail + numFail;
    
    [no_carriage_return_in_name, numFail] =  ...
        check_no_carriage_return_in_name(model,blocks);
    totalFail = totalFail + numFail;
    
    [consecutive_underscore_in_name, numFail] = ...
        check_consecutive_underscore_in_name(model,blocks);
    totalFail = totalFail + numFail;
    
    [starts_with_underscore_in_name, numFail] = ...
        check_starts_with_underscore_in_name(model,blocks);
    totalFail = totalFail + numFail;
    
    [ends_with_underscore_in_name, numFail] = ...
        check_ends_with_underscore_in_name(model,blocks);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
    end
    
    results{end+1} = HtmlItem(title, {no_space_in_name,...
        leading_number_in_name,no_carriage_return_in_name,...
        consecutive_underscore_in_name, starts_with_underscore_in_name,...
        ends_with_underscore_in_name},'black');      
    
end

function [results, numFail] = check_no_space_in_name(model,blocks)
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','\s'),blocks,...  % TODO: needs right regexp
        'should not have blank spaces');
end

function [results, numFail] = check_leading_number_in_name(model,blocks)
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','^[0-9]'),blocks,...  check_starts_with_underscore_in_name
        'should not start with a number');
end

function [results, numFail] = check_no_carriage_return_in_name(model,blocks)
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','\n'),blocks,...  check_starts_with_underscore_in_name
        'carriage returns are not allowed');
end

function [results, numFail] = check_consecutive_underscore_in_name(model,blocks)
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','\r'),blocks,...  check_starts_with_underscore_in_name
        'cannot have more than one consecutive underscore');
end

function [results, numFail] = check_starts_with_underscore_in_name(model,blocks)
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','_*'),blocks,...  check_starts_with_underscore_in_name
        'cannot start with an underscore');
end

function [results, numFail] = check_ends_with_underscore_in_name(model,blocks)
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','Name','*_'),blocks,...  check_starts_with_underscore_in_name
        'cannot end with an underscore');
end

function [results, numFail] = process_find_system_results(fsList,blocks,title)
    numFail = 0;
    failList = cell(1,length(fsList));
    if isempty(fsList)
        failList{1} =  HtmlItem('PASS',{},'green');
    else
        for i=1:length(fsList)
            failList{i} =  HtmlItem(blocks{i},{},'red');
            numFail = 1 + numFail;
        end
    end
    results = HtmlItem(title,failList,'blue');
end

