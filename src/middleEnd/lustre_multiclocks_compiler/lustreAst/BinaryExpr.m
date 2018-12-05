classdef BinaryExpr < LustreExpr
    %BinaryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        op;
        left;
        right;
        withPar; %with parentheses
        addEpsilon;
        epsilon;
    end
    properties(Constant)
        OR = 'or';
        AND = 'and';
        XOR = 'xor';
        IMPLIES = '=>';
        PLUS = '+';
        MINUS = '-';
        MULTIPLY = '*';
        DIVIDE = '/';
        MOD = 'mod';
        EQ = '=';
        NEQ = '<>';
        GTE = '>=';
        LTE = '<=';
        GT = '>';
        LT = '<';
        ARROW = '->';
        MERGEARROW = '->'; % the arrow used in Merge expressions to indicate the clock Value
        WHEN = 'when';
    end
    methods
        %%
        function obj = BinaryExpr(op, left, right, withPar, addEpsilon, epsilon)
            obj.op = op;
            if iscell(left)
                obj.left = left{1};
            else
                obj.left = left;
            end
            if iscell(right)
                obj.right = right{1};
            else
                obj.right = right;
            end
            if ~exist('withPar', 'var') || isempty(withPar)
                obj.withPar = true;
            else
                obj.withPar = withPar;
            end
            if ~exist('addEpsilon', 'var') || isempty(addEpsilon)
                obj.addEpsilon = false;
            else
                obj.addEpsilon = addEpsilon;
            end
            if ~exist('epsilon', 'var') || isempty(epsilon)
                obj.epsilon = [];
            else
                obj.epsilon = epsilon;
            end
        end
        
        function setPar(obj, withPar)
            obj.withPar = withPar;
        end
        %% deepCopy
        function new_obj = deepCopy(obj)
            new_obj = BinaryExpr(obj.op,...
                obj.left.deepCopy(),...
                obj.right.deepCopy(), ...
                obj.withPar);
        end
        %% substituteVars
        function new_obj = substituteVars(obj, oldVar, newVar)
            new_obj = BinaryExpr(obj.op,...
                obj.left.substituteVars( oldVar, newVar),...
                obj.right.substituteVars( oldVar, newVar), ...
                obj.withPar);
        end
         %% simplify expression
        function new_obj = simplify(obj)
            new_op = obj.op;
            left_exp = obj.left.simplify();
            right_exp = obj.right.simplify();
            % x + (-y) => x - y, x - (-y) => x+y
            if isa(right_exp, 'UnaryExpr') ...
                    && isequal(right_exp.op, UnaryExpr.NEG) 
                if isequal(new_op, BinaryExpr.PLUS)
                    right_exp = right_exp.expr;
                    new_op = BinaryExpr.MINUS;
                elseif isequal(new_op, BinaryExpr.MINUS)
                    right_exp = right_exp.expr;
                    new_op = BinaryExpr.PLUS;
                end
            end
            % x+0 => x, x -0 => x
            if (isequal(new_op, BinaryExpr.MINUS) ...
                    || isequal(new_op, BinaryExpr.PLUS) )
                if isequal(new_op, BinaryExpr.PLUS) ...
                        && (isa(left_exp, 'IntExpr') || isa(left_exp, 'RealExpr'))...
                        && left_exp.getValue() == 0
                    new_obj = right_exp;
                    return;
                end
                if (isa(right_exp, 'IntExpr') || isa(right_exp, 'RealExpr'))...
                        && right_exp.getValue() == 0
                    new_obj = left_exp;
                    return;
                end
            end
            new_obj = BinaryExpr(new_op,...
                left_exp,...
                right_exp, ...
                obj.withPar);
        end
        %% nbOcc
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.left.nbOccuranceVar(var) + obj.right.nbOccuranceVar(var);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            [leftExp, varIdLeft] = obj.left.changePre2Var();
            varIds = [varIds, varIdLeft];
            [rightExp, varIdright] = obj.right.changePre2Var();
            varIds = [varIds, varIdright];
            new_obj = BinaryExpr(obj.op,...
                leftExp,...
                rightExp, ...
                obj.withPar);
        end
        function new_obj = changeArrowExp(obj, cond)
            if isequal(obj.op, BinaryExpr.ARROW)
                new_obj = IteExpr(cond, ...
                    obj.left.changeArrowExp(cond),...
                    obj.right.changeArrowExp(cond), ...
                    true);
            else
                new_obj = BinaryExpr(obj.op,...
                    obj.left.changeArrowExp(cond),...
                    obj.right.changeArrowExp(cond), ...
                    obj.withPar);
            end
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = [obj.left.GetVarIds(), obj.right.GetVarIds()];
        end
        
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, ~)
            %BinaryExpr is always on the right of an Equation
            [leftExp, ~] = obj.left.pseudoCode2Lustre(outputs_map, false);
            [rightExp, ~] = obj.right.pseudoCode2Lustre(outputs_map, false);
            new_obj = BinaryExpr(obj.op,...
                leftExp,...
                rightExp, ...
                obj.withPar);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.left);
            addNodes(obj.right);
        end
        
       
        
        %%
        function code = print(obj, backend)
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            if obj.addEpsilon ...
                    && (isequal(obj.op, '>=') || isequal(obj.op, '>') ...
                    || isequal(obj.op, '<=') || isequal(obj.op, '<'))
                if isequal(obj.op, '>=') || isequal(obj.op, '<=')
                    epsilonOp = BinaryExpr.LTE;
                    and_or = 'or';
                else
                    epsilonOp = BinaryExpr.GT;
                    and_or = 'and';
                end
                if isempty(obj.epsilon)
                    if isa(obj.left, 'RealExpr')
                        obj.epsilon = eps(obj.left.getValue());
                    elseif isa(obj.right, 'RealExpr')
                        obj.epsilon = eps(obj.right.getValue());
                    else
                        obj.epsilon = 1e-15;
                    end
                end
                code = sprintf('((%s %s %s) %s abs_real(%s - %s) %s %.30f)', ...
                    obj.left.print(backend),...
                    obj.op, ...
                    obj.right.print(backend), ...
                    and_or, ...
                    obj.left.print(backend),...
                    obj.right.print(backend), ...
                    epsilonOp, ...
                    obj.epsilon);
            else
                code = sprintf('%s %s %s', ...
                    obj.left.print(backend),...
                    obj.op, ...
                    obj.right.print(backend));
                if obj.withPar
                    code = sprintf('(%s)', code);
                end
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end
    end
    
    
    methods(Static)
        % Given many args, this function return the binary operation
        % applied on all arguments.
        function exp = BinaryMultiArgs(op, args, isFirstTime)
            if nargin < 3
                isFirstTime = 1;
            end
            if isempty(args) || numel(args) == 1
                if iscell(args)
                    exp = args{1};
                else
                    exp = args;
                end
            elseif numel(args) == 2
                exp = BinaryExpr(op, ...
                    args{1}, ...
                    args{2},...
                    false);
                if isFirstTime
                    exp = ParenthesesExpr(exp);
                end
            else
                exp = BinaryExpr(op, ...
                    args{1}, ...
                    BinaryExpr.BinaryMultiArgs(op, args(2:end), false), ...
                    false);
                if isFirstTime
                    exp = ParenthesesExpr(exp);
                end
            end
        end
    end
end

