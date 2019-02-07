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
