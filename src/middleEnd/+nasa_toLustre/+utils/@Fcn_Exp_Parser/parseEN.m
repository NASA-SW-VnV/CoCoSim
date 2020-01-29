%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% !
function [tree, expr] = parseEN(expr)
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseNot(expr);
    if ~isempty(match)
        [sym, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEN(expr);
        tree = {'Not',sym};
    else
        [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseUnaryMinus(expr);
    end
end

