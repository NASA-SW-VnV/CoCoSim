%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%f(x)
function [tree, expr] = parseFunc(expr)
    regex = '^[A-Za-z0-9]+\(';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        funcname = regexp(expr, '^[A-Za-z0-9]+', 'match', 'once');
        expr = regexprep(expr, regex,'');
        tree = {'Func', funcname};
        [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseArgs(tree, expr, '(', ')');
    else
        tree = '';
    end
end
