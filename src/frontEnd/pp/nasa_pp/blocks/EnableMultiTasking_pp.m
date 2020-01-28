%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
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
function [status, errors_msg] = EnableMultiTasking_pp( new_model_base )
%EnableMultiTasking_pp detectes the implicite rateTransitions and adds them
%explicitely
status = 0;
errors_msg = {};

configSet = getActiveConfigSet(new_model_base);

try
    param = get_param(configSet, 'EnableMultiTasking');
    set_param(configSet, 'EnableMultiTasking', 'on');
catch
    param = get_param(configSet, 'SolverMode');
    set_param(configSet, 'SolverMode', 'MultiTasking');
    status = 1;
    errors_msg{end + 1} = sprintf('EnableMultiTasking pre-process has failed');
end
try
    set_param(configSet, 'SingleTaskRateTransMsg', 'error');
    set_param(configSet, 'MultiTaskRateTransMsg', 'error');
catch
end
set_param(configSet, 'AutoInsertRateTranBlk', 'off');
solveRateTransitions(new_model_base);
%Go back to user configuration
try
    set_param(configSet, 'EnableMultiTasking', param);
catch
    set_param(configSet, 'SolverMode', param);
end
end

%%
function solveRateTransitions( new_model_base)
code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
try
    warning off;
    evalin('base',code_on);
catch ME
    found = fixCauses({ME});
    if found
        solveRateTransitions(new_model_base);
    end
    return;
end
code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
evalin('base',code_off);
end

%%
function found = fixCauses(causes)
found = false;
for i=1:numel(causes)
    c = causes{i};
    switch c.identifier
        case 'Simulink:SampleTime:IllegalIPortRateTrans'
            found = true;
            msg = c.message;
            % get subsystem path
            tokens = regexp(msg, 'matlab:open\w+\s*\(''([^''])+''', 'tokens', 'once');
            if isempty(tokens)
                continue;
            end
            subsys = tokens{1};
            % get the sample time
            tokens = regexp(msg, '[Tt]he sample time\s+(\d+(\.\d+)?)', 'tokens');
            if length(tokens) ~= 2 || ~iscell(tokens{1})
                continue;
            end
            sampleTimeDst = tokens{1}{1};
            sampleTimeSrc = tokens{2}{1};
            % get the port number
            tokens = regexp(msg, 'at input port\s+(\d+(\.\d+)?)', 'tokens', 'once');
            if isempty(tokens)
                continue;
            end
            portNumber = tokens{1};
            display_msg(sprintf('Add RateTransition with SampleTime %s in input port %s for block %s',...
                sampleTimeDst, portNumber, subsys), MsgType.INFO, 'EnableMultiTasking_pp', '');
            try
                addRateTransition(subsys, portNumber, sampleTimeDst, sampleTimeSrc);
            catch me
                display_msg(me.getReport(), MsgType.DEBUG, 'EnableMultiTasking_pp', '');
                found = false;
                return;
            end
        case 'MATLAB:MException:MultipleErrors'
            f = fixCauses(c.cause);
            found = found || f;
            
    end
end
end

%%
function addRateTransition(subsys, portNumber, sampleTimeDst, sampleTimeSrc)
parent = get_param(subsys, 'Parent');
blockHandles = get_param(subsys,'PortHandles');
line = get_param(blockHandles.Inport(str2double(portNumber)), 'line');
srcPortHandle = get_param(line, 'SrcPortHandle');
srcBlkHanlde = get_param(line, 'SrcBlockHandle');
%stSrc = str2num(sampleTimeSrc);% keep str2num
stDst = str2num(sampleTimeDst);% keep str2num
if strcmp(get_param(srcBlkHanlde, 'BlockType'), 'Inport')
    % the case of Inport of subsystem is different sample time than upper
    % level signal driving it.
    stInport = str2num(get_param(srcBlkHanlde, 'SampleTime'));
    if length(stInport) == 1, stInport(2) = 0; end
    if length(stDst) == 1, stDst(2) = 0; end
    if (stInport(1) == -1 || all(stInport == stDst)) ...
            && ~strcmp(get_param(parent, 'Type'), 'block_diagram')
        subsys = parent;
        try
            parent = get_param(parent, 'Parent');
        catch
            parent = fileparts(parent); 
        end
        portNumber = get_param(srcBlkHanlde, 'Port');
        blockHandles = get_param(subsys,'PortHandles');
        line = get_param(blockHandles.Inport(str2double(portNumber)), 'line');
        srcPortHandle = get_param(line, 'SrcPortHandle');
    end
end
delete_line(line);
subsystemPosition = get_param(subsys, 'Position');
x = subsystemPosition(3) - 60;
y = subsystemPosition(4) - 60;
rateTransBlkName = fullfile(parent, strcat('RateTransition', portNumber));
rt_H = add_block('simulink/Signal Attributes/Rate Transition',...
    rateTransBlkName, ...
    'MakeNameUnique', 'on', ...
    'Integrity', 'off', ...
    'Deterministic', 'off', ...
    'OutPortSampleTime', sampleTimeDst,...
    'Position',[x y (x+20) (y+20)]);
if rt_H < 0
    return;
end

% if  stSrc(1) > stDst(1) 
%     set_param(rt_H, 'Integrity', 'off', 'Deterministic', 'off');
% end
rt_portsHandles = get_param(rt_H, 'PortHandles');
add_line(parent, srcPortHandle, rt_portsHandles.Inport(1), 'autorouting', 'on');
add_line(parent, rt_portsHandles.Outport(1), blockHandles.Inport(str2double(portNumber)), 'autorouting', 'on');

end