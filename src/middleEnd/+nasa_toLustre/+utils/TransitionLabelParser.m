%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
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
    E = '';
    % e.g. Set | Resume
    if ~MatlabUtils.contains(expr1, '[') && ~MatlabUtils.contains(expr1, '{') && ~MatlabUtils.contains(expr1, '/')
        % e.g. Set | Resume
        [~, ~, expr2] = nasa_toLustre.utils.Fcn_Exp_Parser.parse(expr1);
        if numel(expr2) < numel(expr1)
            E = expr1(1:numel(expr1) - numel(expr2));
        else
            E = '';
        end
        return;
    end
    
    % an event can be "after(5, tick)"
    [sym, expr2] = nasa_toLustre.utils.Fcn_Exp_Parser.parseFunc(expr1);
    if ~isempty(sym)
        if numel(expr2) < numel(expr1)
            E = expr1(1:numel(expr1) - numel(expr2));
        else
            E = '';
        end
        return;
    end
    % an event can be "E"
    [sym, expr2] = nasa_toLustre.utils.Fcn_Exp_Parser.parseVar(expr1);
    if ~isempty(sym)
        if numel(expr2) < numel(expr1)
            E = expr1(1:numel(expr1) - numel(expr2));
        else
            E = '';
        end
        return;
    end
    
    
    % an event can be "(E | F)"
    [sym, expr2] = nasa_toLustre.utils.Fcn_Exp_Parser.parsePar(expr1);
    if ~isempty(sym)
        if numel(expr2) < numel(expr1)
            E = expr1(1:numel(expr1) - numel(expr2));
        else
            E = '';
        end
        return;
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
