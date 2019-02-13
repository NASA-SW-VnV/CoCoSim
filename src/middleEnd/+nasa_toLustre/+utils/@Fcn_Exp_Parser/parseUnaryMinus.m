%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [tree, expr] = parseUnaryMinus(expr)
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseMinus(expr);
    if ~isempty(match)
        [sym, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseSE(expr);
        sym1 = {'UnaryMinus',sym};
        [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEM2(expr, sym1);

    else
        [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEM(expr);
    end
end
