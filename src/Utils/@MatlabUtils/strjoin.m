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
