function [status, errors_msg] = EnableMultiTasking_pp( new_model_base )
%EnableMultiTasking_pp detectes the implicite rateTransitions and adds them
%explicitely
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                continue;
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
delete_line(line);
subsystemPosition = get_param(subsys, 'Position');
x = subsystemPosition(3) - 60;
y = subsystemPosition(4) - 60;
rateTransBlkName = fullfile(parent, strcat('RateTransition', portNumber));
rt_H = add_block('simulink/Signal Attributes/Rate Transition',...
    rateTransBlkName, ...
    'MakeNameUnique', 'on', ...
    'OutPortSampleTime', sampleTimeDst,...
    'Position',[x y (x+20) (y+20)]);
if rt_H < 0
    return;
end
stSrc = str2num(sampleTimeSrc);% keep str2num
stDst = str2num(sampleTimeDst);% keep str2num
if  stSrc(1) > stDst(1) 
    set_param(rt_H, 'Integrity', 'off', 'Deterministic', 'off');
end
rt_portsHandles = get_param(rt_H, 'PortHandles');
add_line(parent, srcPortHandle, rt_portsHandles.Inport(1), 'autorouting', 'on');
add_line(parent, rt_portsHandles.Outport(1), blockHandles.Inport(str2double(portNumber)), 'autorouting', 'on');

end