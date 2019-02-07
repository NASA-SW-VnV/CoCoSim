
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
