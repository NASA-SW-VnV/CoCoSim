function [tree, status, unsupportedExp] = Fcn_Exp_Parser(exp)
%Fcn_Exp_Parser generates a tree from a mathematical expression in Fcn
%Block. Fcn Block in Simulink has limited grammar.
exp = regexprep(exp, '\s*', '');
[tree, status, unsupportedExp] = parseE(exp);
end

%%
function [tree, status, expr] = parseE(e)
status = 0;
[tree, expr] = parseEA(e);
if ~isempty(expr)
    status = 1;
end
end

%%
function [tree, expr] = parseEA(expr)
[sym1, expr] = parseEN(expr);
[match, expr] = parsePlus(expr);
if ~isempty(match)
    %the case of x++
    [match, expr] = parsePlus(expr);
    if ~isempty(match)
        tree = {'Plus',sym1, '1.0'};
    else
        [sym2, expr] = parseEA(expr);
        if ~isempty(sym1)
            tree = {'Plus',sym1,sym2};
        else
            tree = {'Plus','0.0',sym2};
        end
    end
else
    [match, expr] = parseMinus(expr);
    if ~isempty(match)
        %the case of x--
        [match, expr] = parseMinus(expr);
        if ~isempty(match)
            tree = {'Minus',sym1, '1.0'};
        else
            [sym2, expr] = parseEA(expr);
            if ~isempty(sym1)
                tree = {'Minus',sym1,sym2};
            else
                tree = {'Minus','0.0',sym2};
            end
        end
    else
        [match, expr] = parseRO(expr);
        if ~isempty(match)
            [sym2, expr] = parseEA(expr);
            tree = {match,sym1,sym2};
        else
            [match, expr] = parseEQ(expr);
            if ~isempty(match)
                [sym2, expr] = parseEA(expr);
                tree = {match,sym1,sym2};
            else
                tree = sym1;
            end
        end
    end
end
end
%% !
function [tree, expr] = parseEN(expr)
[match, expr] = parseNot(expr);
if ~isempty(match)
    [sym, expr] = parseEN(expr);
    tree = {'Not',sym};
else
    [tree, expr] = parseUnaryMinus(expr);
end
end

function [tree, expr] = parseUnaryMinus(expr)
[match, expr] = parseMinus(expr);
if ~isempty(match)
    [sym, expr] = parseSE(expr);
    sym1 = {'UnaryMinus',sym};
    [tree, expr] = parseEM2(expr, sym1);
    
else
    [tree, expr] = parseEM(expr);
end
end
%% *, /, ^
function [tree, expr] = parseEM2(expr, sym1)
[match, expr] = parseMult(expr);
if ~isempty(match)
    [sym2, expr] = parseEA(expr);
    tree = {'Mult',sym1,sym2};
else
    [match, expr] = parseDiv(expr);
    if ~isempty(match)
        [sym2, expr] = parseEA(expr);
        tree = {'Div',sym1,sym2};
    else
        tree = sym1;
    end
end
end
function [tree, expr] = parseEM(expr)
[sym1, expr] = parseEP(expr);
[match, expr] = parseMult(expr);
if ~isempty(match)
    [sym2, expr] = parseEA(expr);
    tree = {'Mult',sym1,sym2};
else
    [match, expr] = parseDiv(expr);
    if ~isempty(match)
        [sym2, expr] = parseEA(expr);
        tree = {'Div',sym1,sym2};
    else
        tree = sym1;
    end
end
end

function [tree, expr] = parseEP(expr)
[sym1, expr] = parseSE(expr);
[match, expr] = parsePow(expr);
if ~isempty(match)
    [sym2, expr] = parseEP(expr);
    tree = {'Pow',sym1,sym2};
else
    tree = sym1;
end
end

%% Number, Function call, ()
function [tree, expr] = parseSE(expr)
[sym, expr] = parseNum(expr);
if isempty(sym)
    [sym, expr] = parseFunc(expr);
    if isempty(sym)
        [sym, expr] = parseVar(expr);
        if isempty(sym)
            [tree, expr] = parsePar(expr);
        else
            tree = sym;
        end
    else
        tree = sym;
    end
else
    tree = sym;
end
end




%% Elementary Pasers
%
function [tree, expr] = parsePar(expr)
if startsWith(expr, '(')
    expr = regexprep(expr, '^\(', '');
    [sym, expr] = parseEA(expr);
    expr = regexprep(expr, '^\)', '');
    tree = {'Par', sym};
else
    tree = '';
end
end

function [tree, expr] = parseNum(expr)
regex = '^-?\+?[0-9]+(\.[0-9]+)?(e-?[0-9]+)?';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex, '');
else
    tree = '';
end
end


function [tree, expr] = parseFunc(expr)
regex = '^[A-Za-z0-9]+(\(|\[)';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    funcname = regexp(expr, '^[A-Za-z0-9]+', 'match', 'once');
    expr = regexprep(expr, regex,'');
    if strcmp(funcname, 'u')
        [arg, expr] = parseEA(expr);
        expr = regexprep(expr, '^(\)|\])','');
        tree = {'Func',funcname,arg};
    else
        tree = {'Func', funcname};
        nbPar = 1;
        i = 1;
        args = {};
        while(nbPar ~= 0)
            if strcmp(expr(i), '(')
                nbPar = nbPar + 1;
                i = i+1;
            elseif strcmp(expr(i), ')')
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
            [argi, ~] = parseEA(args{i});
            tree = [tree, {argi}];
        end
    end
else
    tree = '';
end
end

function [tree, expr] = parseVar(expr)
regex = '^[A-Za-z0-9_]+';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end

function [tree, expr] = parsePlus(expr)
regex = '^\+';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end

function [tree, expr] = parseMinus(expr)
regex = '^-';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end


function [tree, expr] = parseNot(expr)
regex = '^(!|~)';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end

function [tree, expr] = parseMult(expr)
regex = '^\*';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end

function [tree, expr] = parseDiv(expr)
regex = '^/';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end

function [tree, expr] = parsePow(expr)
regex =	'^\^';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end
% > < <= >=, == !=, && ||
function [tree, expr] = parseRO(expr)
regex = '^(<=?|>=?|==|!=|~=|&&?|\|\|?)';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end
% =
function [tree, expr] = parseEQ(expr)
regex = '^(=)';
match = regexp(expr, regex, 'match', 'once');
if ~isempty(match)
    tree = match;
    expr = regexprep(expr, regex,'');
else
    tree = '';
end
end