%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function [isBus, bus] = isSimulinkBus(SignalName, model)
    bus = [];
    if nargin >= 2
        hws = get_param(model, 'modelworkspace') ;
        if hasVariable(hws,SignalName)
            bus = getVariable(hws,SignalName);
            isBus = isa(bus, 'Simulink.Bus');
            return;
        end
    end
    try
        bus = evalin('base', SignalName);
        isBus = isa(bus, 'Simulink.Bus');
    catch
        isBus = false;
    end
end
