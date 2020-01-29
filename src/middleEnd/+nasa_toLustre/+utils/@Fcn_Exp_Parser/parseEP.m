%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

function [tree, expr] = parseEP(expr)
    [sym1, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseSE(expr);
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parsePow(expr);
    if ~isempty(match)
        [sym2, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEP(expr);
        tree = {'Pow',sym1,sym2};
    else
        tree = sym1;
    end
end

