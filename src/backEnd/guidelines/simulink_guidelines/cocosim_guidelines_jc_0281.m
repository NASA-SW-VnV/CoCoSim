%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
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
function [results, passed, priority] = cocosim_guidelines_jc_0281(model)
%    % ORION GN&C MATLAB/Simulink Standards
    % jc_0281: Naming of Trigger Port block and Enable Port block

    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    blockList = find_system(model, 'type', 'block', 'BlockType', ...
        'SubSystem');
    failedTrigger = {};
    failedEnable = {};
    for i = 1:numel(blockList)
        ports = get_param(blockList{i}, 'PortHandles');
        if ~isempty(ports.Trigger)
            trigger = find_system(model, 'type', 'block', ...
                'BlockType', 'TriggerPort', 'Parent', blockList{i});
            triggerName = get_param(trigger, 'Name');
            blockHandle = get_param(blockList{i}, 'Handle');
            line = find_system(model, 'FindAll', 'On', 'type', ...
                'line', 'Name', triggerName{1}, ...
                'DstBlockHandle', blockHandle);
            if isempty(line)
                failedTrigger{end+1} = blockList{i}; %#ok<AGROW>
            end
        end
        
        if ~isempty(ports.Enable)
            enable = find_system(model, 'type', 'block', ...
                'BlockType', 'EnablePort', 'Parent', blockList{i});
            enableName = get_param(enable, 'Name');
            blockHandle = get_param(blockList{i}, 'Handle');
            line = find_system(model, 'FindAll', 'On', ...
                'type', 'line', 'Name', enableName{1}, ...
                'DstBlockHandle', blockHandle);
            if isempty(line)
                failedEnable{end+1} = blockList{i}; %#ok<AGROW>
            end
        end   
    end
    item_title = 'Same name for trigger block and signal';
    [different_trigger_names, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedTrigger, ...
        item_title, true, true);
    totalFail = totalFail + numFail;
    
    item_title = 'Same name for enable block and signal';
    [different_enable_names, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedEnable, ...
        item_title, true, true); 
    totalFail = totalFail + numFail; 
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end        
    
    title = 'jc_0281: Naming of Trigger Port block and Enable Port block';
    description_text = [...
        'For Trigger port blocks and Enable port blocks<br>'...
        '&ensp;- The block name should match the name of the signal '...
        'triggering the subsystem <br>'];    
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        different_trigger_names, ...
        different_enable_names}, ...
        color, color);   

end


