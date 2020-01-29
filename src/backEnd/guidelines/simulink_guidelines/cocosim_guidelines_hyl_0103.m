%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [results, passed, priority] = cocosim_guidelines_hyl_0103(model)

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

