function tf = contains(s, pattern, varargin)
try
    tf = ~isempty(strfind(s, pattern));
catch
    narginchk(2, inf);

    if ~isTextStrict(s)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    end

    try
        stringS = string(s);
        
        if nargin == 2
            tf = stringS.contains(pattern);
        else
            tf = stringS.contains(pattern, varargin{:});
        end

    catch E
        throw(E)
    end
end
end

function tf = isTextStrict(value)
    tf = (ischar(value) && ((isempty(value) && isequal(size(value),[0 0])) || isrow(value))) || isstring(value) || iscellstr(value);
end

