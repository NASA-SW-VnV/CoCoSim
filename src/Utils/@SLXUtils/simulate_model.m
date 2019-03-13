%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% Simulate the model
function simOut = simulate_model(slx_file_name, ...
    input_dataset, ...
    simulation_step,...
    stop_time,...
    numberOfInports,...
    show_models)
    try
        configSet = copy(getActiveConfigSet(slx_file_name));
    catch
        configSet = Simulink.ConfigSet;
    end
    set_param(configSet, 'Solver', 'FixedStepDiscrete');
    set_param(configSet, 'FixedStep', num2str(simulation_step));
    set_param(configSet, 'StartTime', '0.0');
    set_param(configSet, 'StopTime',  num2str(stop_time));
    set_param(configSet, 'SaveFormat', 'Dataset');
    set_param(configSet, 'DatasetSignalFormat', 'timeseries');
    set_param(configSet, 'SaveOutput', 'on');
    set_param(configSet, 'SaveTime', 'on');

    if numberOfInports>=1
        set_param(configSet, 'SaveState', 'on');
        set_param(configSet, 'StateSaveName', 'xout');
        set_param(configSet, 'OutputSaveName', 'yout');
        try set_param(configSet, 'ExtMode', 'on');catch, end
        set_param(configSet, 'LoadExternalInput', 'on');
        set_param(configSet, 'ExternalInput', 'cocosim_input_dataset');
        %hws = get_param(slx_file_name, 'modelworkspace');
        %hws.assignin('input_dataset',eval('input_dataset'));
        assignin('base','cocosim_input_dataset',input_dataset);
        if show_models
            open(slx_file_name)
        end
        warning off;
        simOut = sim(slx_file_name, configSet);
        %warning on;
    else
        if show_models
            open(slx_file_name)
        end
        warning off;
        simOut = sim(slx_file_name, configSet);
        %warning on;
    end
end

