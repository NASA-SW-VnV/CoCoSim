%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% Elementary Pasers
%
function [tree, expr] = parsePar(expr)
    if startsWith(expr, '(')
        expr = regexprep(expr, '^\(', '');
        [sym, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                expr);
            throw(ME);
        end
        expr = expr1;
        expr = regexprep(expr, '^\)', '');
        tree = {'Par', sym};
    else
        tree = '';
    end
end

