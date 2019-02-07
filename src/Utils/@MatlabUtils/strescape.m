
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
