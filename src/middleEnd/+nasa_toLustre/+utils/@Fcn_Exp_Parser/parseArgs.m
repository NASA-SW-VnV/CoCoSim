%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [tree, expr] = parseArgs(tree, expr, lpar, rpar)
    nbPar = 1;
    i = 1;
    args = {};
    while(nbPar ~= 0)
        if strcmp(expr(i), lpar)
            nbPar = nbPar + 1;
            i = i+1;
        elseif strcmp(expr(i), rpar)
            nbPar = nbPar - 1;
            if nbPar == 0
                args{end+1} = expr(1:i-1);
                expr = expr(i+1:end);
                i = 1;
            else
                i = i+1;
            end
        elseif strcmp(expr(i), ',') && nbPar == 1
            args{end+1} = expr(1:i-1);
            expr = expr(i+1:end);
            i = 1;
        else
            i = i+1;
        end
    end
    for i=1:numel(args)
        [argi, ~, isEQ] = nasa_toLustre.utils.Fcn_Exp_Parser.parseEA(args{i});
        if isEQ
            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                args{i});
            throw(ME);
        end
        tree = [tree, {argi}];
    end
end
