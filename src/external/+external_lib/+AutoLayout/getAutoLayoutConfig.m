function val = getAutoLayoutConfig(parameter, default)
% GETAUTOLAYOUTCONFIG Get a parameter from the tool configuration file.
%
%   Inputs:
%       parameter   Configuration parameter to retrieve value for.
%       default     Value to use if parameter is not found.
%
%   Outputs:
%       val         Char configuration value.

    val = default;
    filePath = mfilename('fullpath');
    name = mfilename;
    filePath = filePath(1:end-length(name));
    fileName = [filePath 'config.txt'];
    file = fopen(fileName);
    line = fgetl(file);

    paramPattern = ['^' parameter  ':.*'];

    while ischar(line)
        match = regexp(line, paramPattern, 'match');
        if ~isempty(match)
            val = match{1}; % Get first occurrance
            val = num2str(strrep(val, [parameter ': '], '')); % Strip parameter
            if isempty(val) % No value specified
                val = default;
            end
            break
        end
        line = fgetl(file);
    end
    fclose(file);
end