function [results, passed, priority] = cocosim_guidelines_hyl_0308(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % hyl_0308: Use of reference model name

    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    % Should not start with a number
    title = 'No "reference model" in block name';
    fsList = find_system(model, 'Regexp', 'on','CaseSensitive','off',...
        'blocktype','SubSystem', ...
        'Name', '(model(.*)ref(.*))|(ref(.*)model(.*))');
    [noReferenceInName, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;


    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    %the main guideline
    title = 'hyl_0308: Use of reference model name';
    description_text = [...
        'No block shall be named ?referenced model? (or ?referenced '...
        'model1,? referencedModel1,? etc.).'];
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, noReferenceInName}, color, color);
end
