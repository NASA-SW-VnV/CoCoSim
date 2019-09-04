function [results, passed, priority] = cocosim_guidelines_jc_0121(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0121: Use of the Sum block
    priority = 3;
    results = {};
    passed = 1;
    totalFail = 0;
 
    sumList = find_system(model, 'type', 'block', 'BlockType', 'Sum');
    
    minY = 9;
    failedList = {};
    for i=1:numel(sumList)
        shape = get_param(sumList{i}, 'IconShape');
        input = get_param(sumList{i}, 'Inputs');
        if strcmp(shape, 'rectangular')
            pos = get_param(sumList{i}, 'Position');
            ySize = abs(pos(2) - pos(4));
            if numel(input)*minY > ySize % input signal overlap
                failedList{end+1} = sumList{i}; %#ok<*AGROW>
            end
        else % shape is round
            if numel(input) > 3 % more than 3 inputs or wrong positions
                failedList{end+1} = sumList{i};
            end
        end
        
    end
    
    item_title = 'Wrong sum shape';
    [wrong_sum, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList, ...
        item_title, true, true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
    
    title = 'jc_0121: Use of the Sum block';
    description_text = [...
        'Sum blocks should:<br>'...
        '- Use the "rectangular" shape.<br>'...
        '- Be sized so that the input signals do not overlap.<br>'...
        '- The <b>round</b> shape can be used in feedback loops.<br>'...
        '&ensp;- There should be no more than 3 inputs.<br>'...
        '&ensp;- The inputs may be positioned at 90,180,270 degrees.<br>'...
        '&ensp;- The output should be positioned at 0 degrees.'];
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        wrong_sum}, ...
        color, color);

end


