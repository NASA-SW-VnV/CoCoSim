%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%% Number, Function call, ()
function [tree, expr] = parseSE(expr)
    % e.g. 90
    [sym, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseNum(expr);
    if ~isempty(sym)
        tree = sym;
        return;
    end

    % e.g. f(x)
    [sym, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseFunc(expr);
    if ~isempty(sym)
        tree = sym;
        return;
    end

    % e.g. u[1]
    [sym, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseArray(expr);
    if ~isempty(sym)
        tree = sym;
        return;
    end

    % e.g. x
    [sym, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parseVar(expr);
    if ~isempty(sym)
        tree = sym;
        return;
    end

    % e.g. (expr)
    [tree, expr] = nasa_toLustre.utils.Fcn_Exp_Parser.parsePar(expr);

end


