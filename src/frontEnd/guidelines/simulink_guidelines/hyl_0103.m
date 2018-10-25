function [results, passed] = hyl_0103(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % hyl_0103: Model color coding
        
    %     Don't support checking for non ORION Library blocks
    %     Don't support checking for Domain level blocks (non-CSU)    
    
    % Possible color options from format>background_colors are 'black', ...
    % 'white', 'red', 'green', 'blue', 'cyan', 
    % 'magenta', 'yellow', 'gray', 'lightBlue', 'orange', 'darkGreen'.    
    results = {};
    title = 'hyl_0103: Model color coding';

    passed = 1;
    totalFail = 0;    
    
    [subsystemBlocks, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','SubSystem',...
        'SFBlockType','[^MATLAB Function]','LinkStatus','none',...
        'BackgroundColor','[^lightBlue]'),'Light blue for subsystems blocks');
    totalFail = totalFail + numFail;
    
    [referenceModels, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','ModelReference',...
        'BackgroundColor','[^orange]'),'Orange for referenced models');
    totalFail = totalFail + numFail;
    
    [portBlocks, numFail] =  process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port',...
        'BackgroundColor','[^cyan]'),...
        'Cyan for inport and outport blocks');
    totalFail = totalFail + numFail;
    
    [fromBlocks, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','From',...
        'BackgroundColor','[^yellow]'),...
        'Yellow for From blocks');
    totalFail = totalFail + numFail;
    
    [gotoBlocks, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','Goto$',...
        'BackgroundColor','[^yellow]'),...
        'Yellow for Goto blocks');
    totalFail = totalFail + numFail;    
    
    [gotoTagVisibilityBlocks, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','GotoTagVisibility',...
        'BackgroundColor','[^yellow]'),...
        'Yellow for Goto Tag Visibility blocks');
    totalFail = totalFail + numFail;       
    
    [libraryBlocks, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','LinkStatus','[^none]',...
        'BackgroundColor','white'),'White for Library blocks');
    totalFail = totalFail + numFail;
       
    [embeddedMatlabBlocks, numFail] = process_find_system_results(...
        find_system(model,'Regexp', 'on','SFBlockType','MATLAB Function',...
        'BackgroundColor','[^gray]'),'Gray for Embedded Matlab Blocks');
    totalFail = totalFail + numFail;   
    
    if totalFail > 0
        passed = 0;
    end

    results{end+1} = HtmlItem(title, {subsystemBlocks,...
        referenceModels,portBlocks,fromBlocks,gotoBlocks,...
        gotoTagVisibilityBlocks,...
        libraryBlocks,embeddedMatlabBlocks},'black');

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

