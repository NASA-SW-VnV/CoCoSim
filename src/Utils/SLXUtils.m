classdef SLXUtils
    %SLXUtils Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        %% Try to calculate Block sample time using GCD
        function st = get_BlockDiagram_SampleTime(file_name)
            warning off;
            ts = Simulink.BlockDiagram.getSampleTimes(file_name);
            warning on;
            st = 1;
            for t=ts
                if ~isempty(t.Value) && isnumeric(t.Value)
                    tv = t.Value(1);
                    if ~(isnan(tv) || tv==Inf)
                        st = gcd(st*100,tv*100)/100;
                        
                    end
                end
            end
            
        end
        
        
        %% Concat cell array with a specific delimator
        function joinedStr = concat_delim(str, delimiter)
            if nargin < 1 || nargin > 2
                narginchk(1, 2);
            end
            
            strIsString  = isstring(str);
            strIsCellstr = iscellstr(str);
            
            % Check input arguments.
            if ~strIsCellstr && ~strIsString
                error(message('MATLAB:strjoin:InvalidCellType'));
            end
            
            numStrs = numel(str);
            
            if nargin < 2
                delimiter = {' '};
            elseif ischar(delimiter)
                delimiter = {SLXUtils.strescape(delimiter)};
            elseif iscellstr(delimiter) || isstring(delimiter)
                numDelims = numel(delimiter);
                if numDelims ~= 1 && numDelims ~= numStrs-1
                    error(message('MATLAB:strjoin:WrongNumberOfDelimiterElements'));
                elseif strIsCellstr && isstring(delimiter)
                    delimiter = cellstr(delimiter);
                end
                delimiter = reshape(delimiter, numDelims, 1);
            else
                error(message('MATLAB:strjoin:InvalidDelimiterType'));
            end
            
            str = reshape(str, numStrs, 1);
            
            if strIsString
                if isempty(str)
                    joinedStr = string('');
                else
                    joinedStr = join(str, delimiter);
                end
            elseif numStrs == 0
                joinedStr = '';
            else
                joinedCell = cell(2, numStrs);
                joinedCell(1, :) = str;
                joinedCell(2, 1:numStrs-1) = delimiter;
                
                joinedStr = [joinedCell{:}];
            end
        end
        function str = strescape(str)
            %STRESCAPE  Escape control character sequences in a string.
            %   STRESCAPE(STR) converts the escape sequences in a string to the values
            %   they represent.
            %
            %   Example:
            %
            %       strescape('Hello World\n')
            %
            %   See also SPRINTF.
            
            %   Copyright 2012-2015 The MathWorks, Inc.
            
            if iscell(str)
                str = cellfun(@(c)strescape(c), str, 'UniformOutput', false);
            else
                idx = 1;
                % Note that only [1:end-1] of the string is checked,
                % since unescaped trailing backslashes are ignored.
                while idx < length(str)
                    if str(idx) == '\'
                        str(idx) = [];  % Remove the '\' escape character itself.
                        str(idx) = SLXUtils.escapeChar(str(idx));
                    end
                    idx = idx + 1;
                end
            end
            
        end
        %--------------------------------------------------------------------------
        function c = escapeChar(c)
            switch c
                case '0'  % Null.
                    c = char(0);
                case 'a'  % Alarm.
                    c = char(7);
                case 'b'  % Backspace.
                    c = char(8);
                case 'f'  % Form feed.
                    c = char(12);
                case 'n'  % New line.
                    c = char(10);
                case 'r'  % Carriage return.
                    c = char(13);
                case 't'  % Horizontal tab.
                    c = char(9);
                case 'v'  % Vertical tab.
                    c = char(11);
                case '\'  % Backslash.
                    c = '\';
                otherwise
                    warning(message('MATLAB:strescape:InvalidEscapeSequence', c, c));
            end
        end
        %%
        function out = naming(nomsim)
            [a, b]=regexp (nomsim, '/', 'split');
            out = strcat(a{numel(a)-1},'_',a{end});
        end
        
        %% run constants files
        function run_constants_files(const_files)
            const_files_bak = const_files;
            try
                const_files = evalin('base', const_files);
            catch
                const_files = const_files_bak;
            end
            
            if iscell(const_files)
                for i=1:numel(const_files)
                    if strcmp(const_files{i}(end-1:end), '.m')
                        evalin('base', ['run ' const_files{i} ';']);
                    else
                        vars = load(const_files{i});
                        field_names = fieldnames(vars);
                        for j=1:numel(field_names)
                            % base here means the current Matlab workspace
                            assignin('base', field_names{j}, vars.(field_names{j}));
                        end
                    end
                end
            elseif ischar(const_files)
                if strcmp(const_files(end-1:end), '.m')
                    evalin('base', ['run ' const_files ';']);
                else
                    vars = load(const_files);
                    field_names = fieldnames(vars);
                    for j=1:numel(field_names)
                        % base here means the current Matlab workspace
                        assignin('base', field_names{j}, vars.(field_names{j}));
                    end
                end
            end
        end
        
        %%
        function [model_inputs_struct, inputEvents_names] = get_model_inputs_info(model_full_path)
            %TODO: Need to be optimized
            model_inputs_struct = [];
            try
                load_system(model_full_path);
            catch ME
                error(ME.getReport());
                return;
            end
            [~, slx_file_name, ~] = fileparts(model_full_path);
            rt = sfroot;
            m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', slx_file_name);
            events = m.find('-isa', 'Stateflow.Event');
            inputEvents = events.find('Scope', 'Input');
            inputEvents_names = inputEvents.get('Name');
            code_on=sprintf('%s([], [], [], ''compile'')', slx_file_name);
            warning off;
            evalin('base',code_on);
            block_paths = find_system(slx_file_name, 'SearchDepth',1, 'BlockType', 'Inport');
            for i=1:numel(block_paths)
                block = block_paths{i};
                block_ports_dts = get_param(block, 'CompiledPortDataTypes');
                DataType = block_ports_dts.Outport;
                dimension_struct = get_param(block,'CompiledPortDimensions');
                dimension = dimension_struct.Outport;
                if numel(dimension)== 2 && dimension(1)==1
                    dimension = dimension(2);
                end
                model_inputs_struct = [model_inputs_struct, struct('name',BUtils.naming_alone(block),...
                    'datatype', DataType, 'dimension', dimension)];
                
            end
            code_off=sprintf('%s([], [], [], ''term'')', slx_file_name);
            evalin('base',code_off);
            warning on;
        end
        
        %% create random vector test
        function [input_struct, ...
                simulation_step, ...
                stop_time] = get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN)
            if ~exist('inputEvents_names', 'var')
                inputEvents_names = {};
            end
            if ~exist('nb_steps', 'var')
                nb_steps = 100;
            end
            if ~exist('IMAX', 'var')
                IMAX = 100;
            end
            if ~exist('IMIN', 'var')
                IMIN = -100;
            end
            numberOfInports = numel(inports);
            try
                min = SLXUtils.get_BlockDiagram_SampleTime(slx_file_name);
                if  min==0 || isnan(min) || min==Inf
                    simulation_step = 1;
                else
                    simulation_step = min;
                end
                
            catch
                simulation_step = 1;
            end
            stop_time = (nb_steps - 1)*simulation_step;
            input_struct.time = (0:simulation_step:stop_time)';
            input_struct.signals = [];
            for i=1:numberOfInports
                input_struct.signals(i).name = inports(i).name;
                if isfield(inports(i), 'dimension')
                    dim = inports(i).dimension;
                else
                    dim = 1;
                end
                if numel(IMIN) >= i && numel(IMAX) >= i
                    min = IMIN(i);
                    max = IMAX(i);
                else
                    min = IMIN(1);
                    max = IMAX(1);
                end
                if find(strcmp(inputEvents_names,inports(i).name))
                    input_struct.signals(i).values = square((numberOfInports-i+1)*rand(1)*input_struct.time);
                    input_struct.signals(i).dimensions = 1;
                elseif strcmp(LusValidateUtils.get_lustre_dt(inports(i).datatype),'bool')
                    input_struct.signals(i).values = LusValidateUtils.construct_random_booleans(nb_steps, min, max, dim);
                    input_struct.signals(i).dimensions = dim;
                elseif strcmp(LusValidateUtils.get_lustre_dt(inports(i).datatype),'int')
                    input_struct.signals(i).values = LusValidateUtils.construct_random_integers(nb_steps, min, max, inports(i).datatype, dim);
                    input_struct.signals(i).dimensions = dim;
                elseif strcmp(inports(i).datatype,'single')
                    input_struct.signals(i).values = single(LusValidateUtils.construct_random_doubles(nb_steps, min, max, dim));
                    input_struct.signals(i).dimensions = dim;
                else
                    input_struct.signals(i).values = LusValidateUtils.construct_random_doubles(nb_steps, min, max, dim);
                    input_struct.signals(i).dimensions = dim;
                end
                
            end
           
        end
    end
    
end

