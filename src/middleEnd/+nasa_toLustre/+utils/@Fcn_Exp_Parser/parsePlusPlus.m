%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [tree, expr] = parsePlusPlus(expr)
    regex = '^\+{2}';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        tree = match;
        expr = regexprep(expr, regex,'');
    else
        tree = '';
    end
end
