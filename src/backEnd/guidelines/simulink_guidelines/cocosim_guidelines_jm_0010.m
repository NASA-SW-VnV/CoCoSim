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
function [results, passed, priority] = cocosim_guidelines_jm_0010(model)

    % jm_0010: Port block name in Simulink model
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    item_title = 'Inport must match corresponding signal or bus name';
    failedList = {};
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port');
    for i=1:numel(portBlocks)
        portHandles = get_param(portBlocks{i}, 'PortHandles');
        line = get_param(portHandles.Outport, 'line');
        lineName = get_param(line, 'Name');
        portname = get_param(portBlocks{i}, 'Name');
        if ~MatlabUtils.startsWith(portname, lineName)
            if ~MatlabUtils.endsWith(portname, lineName)
                failedList{end+1} = portBlocks{i};
            end
        end
    end
    [Inport_match_signal, numFail] = ...
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
        if ~MatlabUtils.startsWith(portname, lineName)
            if ~MatlabUtils.endsWith(portname, lineName)
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
    title = 'jm_0010: Port block name in Simulink model';
    description_text = [...
        'The names of Inport blocks and Outport blocks must match the '...
        'corresponding signal or bus names. <br>'...
        '<b>Exceptions: </b><br>'...
            '&emsp;- When any combination of an Inport block, an Outport '...
            'block, and any other block have the same block name, a '...
            'suffix or prefix should be used on the Inport and Outport '...
            'blocks.<br>'...
            '&emsp;- One common suffix is "_In" for Inportsand "_Out" for '...
            'Outports.<br>'...
            '&emsp;- Any suffix or prefix can be used on the ports, '...
            'however the selected option should be consistent.<br>'...
            '&emsp;- Library blocks and reusable subsystems that '...
            'encapsulate generic functionality.'];
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        Inport_match_signal,...
        Outport_match_signal}, ...
        color, color);    

end


