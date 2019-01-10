classdef MatlabUtils
    %MatlabUtils contains all functions help in coding in Matlab.
    properties
    end
    
    methods (Static = true)
        
        %% concatenate 1-D vectors
        function r = concat(v1, v2)
            [n1, ~] = size(v1);
            [n2, ~] = size(v2);
            if n1 == 1
                if n2 == 1
                    r = [v1, v2];
                else
                    r = [v1, v2'];
                end
            else
                if n2 == 1
                    r = [v1; v2'];
                else
                    r = [v1; v2];
                end
            end
        end
        %%
        function out = naming(nomsim)
            [a, ~]=regexp (nomsim, '/', 'split');
            out = strcat(a{numel(a)-1},'_',a{end});
        end
        
        %%
        function mkdir(path)
            tokens = regexp(path, filesep, 'split');
            for i=2:numel(tokens)
                d = MatlabUtils.strjoin(tokens(1:i), filesep);
                if ~exist(d, 'dir')
                    mkdir(d);
                end
            end
        end
        
        %%
        function st = gcd(T)
            st = max(T);
            for i=1:numel(T)
                st = gcd(st*10000,T(i)*10000)/10000;
            end
        end
        %%
        function  diff1in2  = setdiff_struct( struct2, struct1, fieldname )
            %return the elements in struct2 that are not in struct1
            if isempty(struct2)
                diff1in2 = [];
            elseif isempty(struct1)
                diff1in2 = struct2;
            else
                AA = struct2(~cellfun(@isempty,{struct2.(fieldname)}));
                BB = struct1(~cellfun(@isempty,{struct1.(fieldname)}));
                A = {AA.(fieldname)} ;
                B = {BB.(fieldname)} ;
                [~,ia] = setdiff(A,B) ;
                diff1in2 = struct2(ia) ;
            end
        end
        function res = structUnique(struct2, fieldname)
            
            res = struct2;
            if isempty(struct2)
                return;
            end
            if iscell(struct2)
                A = cellfun(@(x) {x.(fieldname)},struct2);
            else
                AA = struct2(~cellfun(@isempty,{struct2.(fieldname)}));
                A = {AA.(fieldname)};
            end
            [~,ia] = unique(A) ;
            res = struct2(ia) ;
        end
        
        %% removeEmpty
        function l = removeEmpty(l)
            l = l(cellfun(@(x) ~isempty(x), l));
        end
        %%
        function tf = startsWith(s, pattern)
            try
                %use Matlab startsWith for Matlab versions > 2015
                tf = startsWithw(s, pattern);
            catch
                try
                    res = regexp(s, strcat('^', pattern), 'match', 'once');
                    if ischar(res)
                        res = {res};
                    end
                    tf = cellfun(@(x) ~isempty(x), res);
                catch E
                    throw(E);
                end
            end
        end
        %%
        function tf = endsWith(s, pattern)
            try
                %use Matlab startsWith for Matlab versions > 2015
                tf = endsWith(s, pattern);
            catch
                try
                    res = regexp(s, strcat(pattern, '$'), 'match', 'once');
                    if ischar(res)
                        res = {res};
                    end
                    tf = cellfun(@(x) ~isempty(x), res);
                catch E
                    throw(E);
                end
            end
        end
        
        %% delete files using regular expressions:
        %e.g. rm *_PP.slx
        function reg_delete(basedir, reg_exp)
            all_files = dir(fullfile(basedir,'**', reg_exp));
            if isfield(all_files, 'folder')
                files_path = arrayfun(@(x) [x.folder '/' x.name], all_files, 'UniformOutput', 0);
            elseif isfield(all_files, 'name')
                files_path = {all_files.name};
            else
                files_path = {};
            end
            for i=1:numel(files_path)
                delete(files_path{i});
            end
        end
        %% Concat cell array with a specific delimator
        function joinedStr = strjoin(str, delimiter)
            if nargin < 1 || nargin > 2
                narginchk(1, 2);
            end
            
            strIsCellstr = iscellstr(str);
            
            % Check input arguments.
            if ~strIsCellstr
                error(message('MATLAB:strjoin:InvalidCellType'));
            end
            
            numStrs = numel(str);
            
            if nargin < 2
                delimiter = {' '};
            elseif ischar(delimiter)
                delimiter = {MatlabUtils.strescape(delimiter)};
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
            
            if numStrs == 0
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
                        str(idx) = MatlabUtils.escapeChar(str(idx));
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
        
    end
    
end

