%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tree, expr, isAssignement] = parseEA(expr)
    isAssignement = 0;
    [sym1, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEN(expr);

    %x++
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parsePlusPlus(expr);
    if ~isempty(match)
        %the case of x++
        tree = {'=', sym1, {'Plus',sym1, '1.0'}};
        isAssignement = 1;
        return;
    end

    %x--
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseMinusMinus(expr);
    if ~isempty(match)
        %the case of x--
        tree = {'=', sym1, {'Minus',sym1, '1.0'}};
        isAssignement = 1;
        return;
    end

    %sym1 + sym2
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parsePlus(expr);
    if ~isempty(match)
        [sym2, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                expr);
            throw(ME);
        end
        expr = expr1;
        if ~isempty(sym1)
            tree = {'Plus',sym1,sym2};
        else
            tree = {'Plus','0.0',sym2};
        end
        return;
    end

    %sym1 - sym2
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseMinus(expr);
    if ~isempty(match)
        [sym2, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                expr);
            throw(ME);
        end
        expr = expr1;
        if ~isempty(sym1)
            tree = {'Minus',sym1,sym2};
        else
            tree = {'Minus','0.0',sym2};
        end
        return;
    end

    % > < <= >=, == !=, && ||
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseRO(expr);
    if ~isempty(match)
        [sym2, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                expr);
            throw(ME);
        end
        expr = expr1;
        tree = {match,sym1,sym2};
        return;
    end

    % sym1 = sym2
    [match, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEQ(expr);
    if ~isempty(match)
        [sym2, expr1, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(expr);
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                expr);
            throw(ME);
        end
        expr = expr1;
        tree = {match,sym1,sym2};
        return;
    end

    % return sym1
    tree = sym1;

end
