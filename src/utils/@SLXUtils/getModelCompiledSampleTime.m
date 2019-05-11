%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% Try to calculate Block sample time using the model
function [st, ph, Clocks] = getModelCompiledSampleTime(file_name)
    st = 1;
    ph = 0;
    Clocks = {};
    try
        warning off;
        ts = Simulink.BlockDiagram.getSampleTimes(file_name);
        %warning on;
    catch ME
        display_msg(ME.getReport(), MsgType.ERROR, 'SLXUtils.getModelCompiledSampleTime', '' );
        st = 1;
        return;
    end
    T = [];
    P = [];
    for t=ts
        v = t.Value;
        if ~isempty(v) && isnumeric(v)
            sv = v(1);
            if numel(v) >= 2, pv = v(2); else, pv = 0; end
            if ~(isnan(sv) || sv==Inf)
                T(end +1) = sv;
                P(end +1) = pv;
                Clocks{end+1} = [sv, pv];
            end
        end
    end
    if isempty(P)
        P = 0;
    end
    if isempty(T)
        return;
    end
    if prod(P/P(1)) == 1
        st = MatlabUtils.gcd(T);
        ph = mod(P(1), st);
    else
        st = MatlabUtils.gcd([T, P]);
        ph = 0;
    end
    %st = gcd(st*10000,tv*10000)/10000;
end


