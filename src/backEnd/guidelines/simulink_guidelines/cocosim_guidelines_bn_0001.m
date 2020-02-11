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
function [results, passed, priority] = cocosim_guidelines_bn_0001(model)

    % bn_0001: Subsystem Name Length Limit
    % 32 characters is the maximum limit
    
    priority = 2; % strongly recommended
    results = {};
    passed = 1;
    totalFail = 0;
    
    SubsystemList = find_system(model, 'Regexp', 'on',...
        'blocktype', 'SubSystem');
    SSNames = get_param(SubsystemList, 'Name');
    failedList = {};
    % we check for uniqueness
    title = 'unique name';
    uniqueSubsystemNames = unique(SSNames);
    unique_names = {};
    if length(uniqueSubsystemNames) < length(SSNames)
        uniqueNames = unique(SSNames);
        for i=1:length(uniqueNames)
            failedList = SubsystemList(strcmp(uniqueNames{i},SSNames));
            if length(failedList) > 1
                unique_names{end+1}= GuidelinesUtils.process_find_system_results(failedList, ...
                    uniqueNames{i}, true);
                totalFail = totalFail + 1;
            end
        end
    end
    if ~isempty(unique_names)
        uniqItem = HtmlItem(title, unique_names, 'red', 'red');
    else 
        uniqItem = HtmlItem(title, unique_names, 'green', 'green');
    end
    
    % we check for name length limit
    title = 'maximum limit of 32 characters';
    Names = get_param(SubsystemList, 'Name');
    lengths = cellfun(@(x) length(x), Names);
    % remove names less than
    failedList = SubsystemList(lengths > 32);
    %add parent
    %failedList = GuidelinesUtils.ppSussystemNames(list);
    [max_limit_32_chars_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList, title, ...
        true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
    
    % the main guideline
    title = 'bn_0001: Subsystem name length limit'; 
    description_text1 = ...
        'The names of all Subsystem blocks must be unique';
    description1 = HtmlItem(description_text1, {}, 'black', 'black');
    description_text2 = ...
        '32 characters is the maximum limit for subsystem name length';
    description2 = HtmlItem(description_text2, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description1, uniqItem, ...
        description2, max_limit_32_chars_in_name}, ...
        color, color);
    
end


