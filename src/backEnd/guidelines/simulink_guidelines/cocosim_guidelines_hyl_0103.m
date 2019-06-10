function [results, passed, priority] = cocosim_guidelines_hyl_0103(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
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
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;    
    
    % a) Light blue for subsystems blocks
    [subsystemBlocks, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','SubSystem',...
        'SFBlockType','[^MATLAB Function]','LinkStatus','none',...
        'BackgroundColor','[^lightBlue]'),...
        'Light blue for subsystems blocks', true);
    totalFail = totalFail + numFail;
    
    % b) Orange for referenced models
    [referenceModels, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','ModelReference',...
        'BackgroundColor','[^orange]'),'Orange for referenced models',...
        true);
    totalFail = totalFail + numFail;
    
    % c) Cyan for inport and outport blocks
    [portBlocks, numFail] =  ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','port',...
        'BackgroundColor','[^cyan]'),...
        'Cyan for inport and outport blocks',true);
    totalFail = totalFail + numFail;
    
    % d) Yellow for From
    [fromBlocks, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','From',...
        'BackgroundColor','[^yellow]'),...
        'Yellow for From blocks',true);
    totalFail = totalFail + numFail;
    
    % d) Yellow for Goto
    [gotoBlocks, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','Goto$',...
        'BackgroundColor','[^yellow]'),...
        'Yellow for Goto blocks',true);
    totalFail = totalFail + numFail;    
    
    % d) Yellow for Goto Visibility tags
    [gotoTagVisibilityBlocks, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','blocktype','GotoTagVisibility',...
        'BackgroundColor','[^yellow]'),...
        'Yellow for Goto Tag Visibility blocks',true);
    totalFail = totalFail + numFail;       
    
    % f) White for Library blocks
    [libraryBlocks, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','LinkStatus','[^none]',...
        'BackgroundColor','white'),'White for Library blocks',true);
    totalFail = totalFail + numFail;
       
    % g)Gray for Embedded Matlab Blocks
    [embeddedMatlabBlocks, numFail] = ...
        GuidelinesUtils.process_find_system_results(...
        find_system(model,'Regexp', 'on','SFBlockType','MATLAB Function',...
        'BackgroundColor','[^gray]'),'Gray for Embedded Matlab Blocks',...
        true);
    totalFail = totalFail + numFail;   
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    title = 'hyl_0103: Model color coding';
    description_text = ...
        'The background color shall be set to:';    
    description = HtmlItem(description_text, {}, 'black', 'black');    
    results{end+1} = HtmlItem(title, ...
        {description, subsystemBlocks,...
         referenceModels,portBlocks,fromBlocks,gotoBlocks,...
         gotoTagVisibilityBlocks,...
         libraryBlocks,embeddedMatlabBlocks}, ...
        color, color);    
    

end

