function inputSignalsInlined = inlineInputSignals(InputSignals, main_cell, prefix)
    % this function takes InputSignals parameter and inline it.
    %example
    % InputSignals = {'x4', {'bus2', {{'bus1', {'chirp', 'sine'}}, 'step'}}}
    % inputSignalsInlined = { 'x4', 'bus2.bus1.chirp', 'bus2.bus1.sine', 'bus2.step'}
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
            nasa_toLustre.blocks.BusSelector_To_Lustre.inlineInputSignals(InputSignals{2}, 0, prefix);
    else
        for i=1:numel(InputSignals)
            if iscell(InputSignals{i})
                inputSignalsInlined = [inputSignalsInlined, ...
                    nasa_toLustre.blocks.BusSelector_To_Lustre.inlineInputSignals(InputSignals{i}, 0, prefix)];
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


