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
function [results, passed, priority] = cocosim_guidelines_na_0009(model)

    % na_0009: Entry versus propagation of signal labels

    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    allLines = find_system(model,'FindAll', 'On', 'type', 'line');
    % Intialize Line Information Class
    %allLineProperties = LineInformation;
    % Parse through lines and Assign the object properties.
    for i = 1 : length(allLines)
        %allLineProperties(i).Identifier =  allLines(i);
        sourceData = get_param(allLines(i),'SrcBlockHandle');
        destinationData = get_param(allLines(i),'DstBlockHandle');
        sourcePortData = get_param(allLines(i),'SrcportHandle');
        destinationPortData = get_param(allLines(i),'DstportHandle');
        SourceBlock =  get_param(sourceData, 'Name');
        DestinationBlock =  get_param(destinationData, 'Name');
        SourcePort =  get_param(sourcePortData, 'Name');
        DestinationPort =  get_param(destinationPortData, 'Name');
    end

    %         lineList = find_system(model, 'Regexp', 'on','FindAll','on',...
    %             'type','line');
    %     for i=1:numel(lineList)
    %         lineName = get_param(lineList(i),'Name');
    %         source = get_param(lineList(i), 'SourceBlock');
    %         % if < , then propagate
    %         display(lineName);
    %         display(source);
    %     end    
    % get linesNames      two type with/without brackets
    % get_param(lineHandle, 'Source')
    % create entered_blocksTypes = {'Inport', 'BusCreator' ...} propagated_blockTypes= {'SubSystem', 'Chart'}

    item_title = 'Inport block';
    failedList = {};
    [Inport_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;
    
    item_title = 'Outport must match corresponding signal or bus name';
    failedList = {};
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port');
    for i=1:numel(portBlocks)
        portHandles = get_param(portBlocks{i}, 'PortHandles');
        line = get_param(portHandles.Inport, 'line');
        lineName = get_param(line, 'Name');
        portname = get_param(portBlocks{i}, 'Name');
        if ~coco_nasa_utils.MatlabUtils.startsWith(portname, lineName)
            if ~coco_nasa_utils.MatlabUtils.endsWith(portname, lineName)
                failedList{end+1} = portBlocks{i};
            end
        end
    end
    [Outport_match_signal, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;    
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end        
    
    title = 'na_0009: Entry versus propagation of signal labels';
    description_text = [...
        'If a label is present on a signal, the following rules define '...
        'whether that label shall be created there (entered directly '...
        'on the signal) or propagated from its true source '...
        '(inherited from elsewhere in the model by using the "<" character). <br>'...
        '&ensp;1. Any displayed signal label must be entered for signals that: <br>'...
        '&emsp;a. Originate from an Inport at the Root (top) Level of a model <br>'...
        '&emsp;b. Originate from a basic block that performs a transformative operation '...
        '         (For the purpose of interpreting this rule only, the Bus Creator block, '...
        '         Mux block and Selector block shall be considered to be included among '...
        '         the blocks that perform transformative operations.) <br>'...
        '&ensp;2. Any displayed signal label must be propagated for signals that: <br>'...
        '&emsp;a. Originate from an Inport block in a nested subsystem<br>'...
        '        <b>Exception:</b> If the nested subsystem is a library subsystem, a label may '...
        '        be entered on the signal coming from the Inport to accommodate reuse '...
        '        of the library block. <br>'...
        '&emsp;b. Originate from a basic block that performs a '...
        '        non-transformative operation <br>'...
        '&emsp;c. Originate from a Subsystem or Stateflow chart block <br>'...
        '        <b>Exception:</b> If the connection originates from the output of a library '...
        '        subsystem block instance, a new label may be entered on the signal to '...
        '        accommodate reuse of the library block.'];    
    
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        Outport_match_signal}, ...
        color, color);   

end


