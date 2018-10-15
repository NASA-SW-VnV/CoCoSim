function [transitionStruct, status, unsupportedExp] = TransitionLabelParser(exp)
    %TransitionLabelParser parse the Stateflow transition label E[C]{Ac}/At
    exp = regexprep(exp, '(\s*|\n*|\.{3}|\?)', '');
    %remove comments in the label
    %before we need to change %%
    expression = '%%';
    replace = ' mod ';
    exp = regexprep(exp,expression,replace);
    exp = regexprep(exp, '(/\*(\s*\w*\W*\s*)*\*/|\%[^\%]*)', '');
    [event, condition, condAction, transAction, unsupportedExp] = parseE(exp);
    status = 0;
    if ~isempty(unsupportedExp)
        status = 1;
    end
    transitionStruct.eventOrMessage = event;
    transitionStruct.condition = condition;
    transitionStruct.conditionAction = condAction;
    transitionStruct.transitionAction = transAction;
end


function [event, condition, condAction, transAction, expr] = parseE(e)
    [event, expr] = parseEvent(e);
    [condition, expr] = parseCondition(expr);
    [condAction, expr] = pareCondAction(expr);
    [transAction, expr] = pareTransAction(expr);
end

function [E, expr2] = parseEvent(expr1)
    if ~contains(expr1, '[') && ~contains(expr1, '{') && ~contains(expr1, '/')
        % e.g. Set | Resume
        [~, ~, expr2] = Fcn_Exp_Parser.parse(expr1);
        if numel(expr2) < numel(expr1)
            E = expr1(1:numel(expr1) - numel(expr2));
        else
            E = '';
        end
    else
        % an event can be "after(5, tick)"
        [sym, expr2] = Fcn_Exp_Parser.parseFunc(expr1);
        if isempty(sym)
            % an event can be "E"
            [sym, expr2] = Fcn_Exp_Parser.parseVar(expr1);
            if isempty(sym)
                % an event can be "(E | F)"
                [sym, expr2] = Fcn_Exp_Parser.parsePar(expr1);
                if isempty(sym)
                    E = '';
                else
                    if numel(expr2) < numel(expr1)
                        E = expr1(1:numel(expr1) - numel(expr2));
                    else
                        E = '';
                    end
                end
            else
                if numel(expr2) < numel(expr1)
                    E = expr1(1:numel(expr1) - numel(expr2));
                else
                    E = '';
                end
            end
        else
            if numel(expr2) < numel(expr1)
                E = expr1(1:numel(expr1) - numel(expr2));
            else
                E = '';
            end
        end
    end
end


function [C, expr] = parseCondition(expr)
    regex = '^\[';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        expr = regexprep(expr, regex, '');
        nbPar = 1;
        i = 1;
        C = '';
        while(nbPar ~= 0)
            if strcmp(expr(i), '[')
                nbPar = nbPar + 1;
                i = i+1;
            elseif strcmp(expr(i), ']')
                nbPar = nbPar - 1;
                if nbPar == 0
                    C = expr(1:i-1);
                    expr = expr(i+1:end);
                else
                    i = i+1;
                end
            else
                i = i+1;
            end
        end
    else
        C = '';
    end
end

function [Ac, expr] = pareCondAction(expr)
    regex = '^\{';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        expr = regexprep(expr, regex, '');
        i = 1;
        Ac = '';
        while(i <= numel(expr))
            if strcmp(expr(i), '}')
                Ac = expr(1:i-1);
                expr = expr(i+1:end);
                break;
            else
                i = i+1;
            end
        end
    else
        Ac = '';
    end
end

function [At, expr] = pareTransAction(expr)
    regex = '^/';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        expr = regexprep(expr, regex, '');
        %trigger[condition]{condition_action}/{transition_action}
        %or trigger[condition]{condition_action}/transition_action
        [Ac, expr] = pareCondAction(expr);
        if isempty(Ac)
            At = expr;
            expr = '';
        else
            At = Ac;
        end
    else
        At = '';
    end
end