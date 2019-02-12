
% this function takes InputSignals parameter and inline it.
%example
% InputSignals = {'x4', {'bus2', {{'bus1', {'chirp', 'sine'}}, 'step'}}}
% inputSignalsInlined = { 'x4', 'bus2.bus1.chirp', 'bus2.bus1.sine', 'bus2.step'}
function inputSignalsInlined = inlineInputSignals(InputSignals, main_cell, prefix)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if nargin < 2
        main_cell = 1;
    end
    if nargin < 3
        prefix = '';
    end
    inputSignalsInlined = {};
    if ~main_cell ...
            && numel(InputSignals) == 2 ...
            && ischar(InputSignals{1}) ...
            && iscell(InputSignals{2})
        % the case of nested type
        if isempty(prefix)
            prefix = InputSignals{1};
        else
            prefix = sprintf('%s.%s', prefix, InputSignals{1});
        end
        inputSignalsInlined = ...
            BusSelector_To_Lustre.inlineInputSignals(InputSignals{2}, 0, prefix);
    else
        for i=1:numel(InputSignals)
            if iscell(InputSignals{i})
                inputSignalsInlined = [inputSignalsInlined, ...
                    BusSelector_To_Lustre.inlineInputSignals(InputSignals{i}, 0, prefix)];
            else
                if isempty(prefix)
                    inputSignalsInlined{end+1} = InputSignals{i};
                else
                    inputSignalsInlined{end+1} = sprintf('%s.%s', prefix, InputSignals{i});
                end
            end
        end
    end
end


