%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%% Try to calculate Sabsystem sample time using the model
function [st, ph] = getSSSampleTime(Clocks, main_sampleTime)
    st = main_sampleTime(1);
    ph = main_sampleTime(2);
    T = [];
    P = [];
    if iscell(Clocks)
        for i=1:length(Clocks)
            v = Clocks{i};
            if ~isempty(v) && isnumeric(v)
                sv = v(1);
                if numel(v) >= 2, pv = v(2); else, pv = 0; end
                if ~(isnan(sv) || sv==Inf || sv < 0)
                    T(end +1) = sv;
                    P(end +1) = pv;
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
    else
        st = Clocks(1);
        ph = Clocks(2);
    end
    
end


