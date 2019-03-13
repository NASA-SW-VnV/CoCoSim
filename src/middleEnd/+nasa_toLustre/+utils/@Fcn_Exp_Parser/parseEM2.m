%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% *, /, ^
function [tree, expr] = parseEM2(expr, sym1)
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseMult(expr);
    if ~isempty(match)
        [sym2, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                expr);
            throw(ME);
        end
        expr = expr1;
        tree = {'Mult',sym1,sym2};
    else
        [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseDiv(expr);
        if ~isempty(match)
            [sym2, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
            if isEQ
                ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                    'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                    expr);
                throw(ME);
            end
            expr = expr1;
            tree = {'Div',sym1,sym2};
        else
            tree = sym1;
        end
    end
end
