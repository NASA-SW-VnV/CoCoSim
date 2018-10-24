function [results, passed] = hyl_0103(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % hyl_0103: Model color coding
    results = {};
    title = 'hyl_0103: Model color coding';

    passed = 1;
    totalFail = 0;    
    
    [subsystemBlocks, numFail] = ...
        check_subsystemBlocks(model);
    totalFail = totalFail + numFail;
    
    [referenceModels, numFail] = ...
        check_referenceModels(model);
    totalFail = totalFail + numFail;
    
    [portBlocks, numFail] =  ...
        check_portBlocks(model);
    totalFail = totalFail + numFail;
    
    [fromGotoBlocks, numFail] = ...
        check_fromGotoBlocks(model);
    totalFail = totalFail + numFail;
    
    [nonOrionLibraryBlocks, numFail] = ...
        check_nonOrionLibraryBlocks(model);
    totalFail = totalFail + numFail;
    
    [libraryBlocks, numFail] = ...
        check_libraryBlocks(model);
    totalFail = totalFail + numFail;
       
    [embeddedMatlabBlocks, numFail] = ...
        check_embeddedMatlabBlocks(model);
    totalFail = totalFail + numFail;
    
    [domainLevelBlocks, numFail] = ...
        check_domainLevelBlocks(model);
    totalFail = totalFail + numFail;    
    
    if totalFail > 0
        passed = 0;
    end

    results{end+1} = HtmlItem(title, {subsystemBlocks,...
        referenceModels,portBlocks,...
        fromGotoBlocks, nonOrionLibraryBlocks,...
        libraryBlocks,embeddedMatlabBlocks,domainLevelBlocks},'black');

end

function [results, numFail] = check_subsystemBlocks(model)
    %TODO develop and test this function
    numFail = 0;
    failList = {};
    curList = find_system(model,'Regexp', 'on','blocktype','SubSystem');
    for i=1:length(curList)
        if ~compareColor(get_param(curList{i},'BackgroundColor'),'lightBlue')
            failList{end + 1} = curList{i};
            numFail = numFail + 1;
        end 
    end
    [results, numFail] = process_find_system_results(failList,...
        'Light blue for subsystems blocks');
end

function [results, numFail] = check_referenceModels(model)
%TODO develop and test this function
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...
        'Orange for referenced models');
end

function [results, numFail] = check_portBlocks(model)
%TODO develop and test this function
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...  
        'Cyan for inport and outport blocks');
end

function [results, numFail] = check_fromGotoBlocks(model)
%TODO develop and test this function
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...  
        'Yellow for From Goto, and Goto Visibility tags');
end

function [results, numFail] = check_nonOrionLibraryBlocks(model)
%TODO develop and test this function
    Red_non_ORION_Lib_RGB = [1.000000, 0.501961, 0.501961];
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...  
        'Red for non ORION Library blocks ');
end

function [results, numFail] = check_libraryBlocks(model)
%TODO develop and test this function
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...  
        'White for Library blocks');
end

function [results, numFail] = check_embeddedMatlabBlocks(model)
%TODO develop and test this function
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...  
        'Gray for Embedded Matlab Blocks');
end

function [results, numFail] = check_domainLevelBlocks(model)
%TODO develop and test this function
    Light_Brown_Domain_level_RGB = [0.792157, 0.772549, 0.725490];
    [results, numFail] = ...
        process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port','Name','\s'),...  
        'Light Brown for Domain level blocks (non-CSU)');
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

function sameColor = compareColor(inCol,refCol)
%TODO develop and test this function
% Possible color values are 'black', 'white', 'red', 'green', 'blue', 'cyan', 
% 'magenta', 'yellow', 'gray', 'lightBlue', 'orange', 'darkGreen'.
    sameColor = 0;
    if isstring(inCol) && isstring(refCol)
        sameColor = strcmp(inCol,refCol);
    end
    
    if isnumeric(inCol) && isnumeric(refCol)
        if sum(inCol==reCol) == 0
            sameColor = 1;
        end
    end

    if isstring(inCol) % refCol is numeric
        
    end
    
    if isnumeric(inCol) % refCol is string
        if sum(inCol==reCol) == 0
            sameColor = 1;
        end
    end    

end
