%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%u[2]
function [tree, expr] = parseArray(expr)
    regex = '^[A-Za-z0-9]+\[';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        varname = regexp(expr, '^[A-Za-z0-9]+', 'match', 'once');
        expr = regexprep(expr, regex,'');
        tree = {'Array', varname};
        [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseArgs(tree, expr, '[', ']');
    else
        tree = '';
    end
end
