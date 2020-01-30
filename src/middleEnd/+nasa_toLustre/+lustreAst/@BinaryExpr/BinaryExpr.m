classdef BinaryExpr < nasa_toLustre.lustreAst.LustreExpr
    %BinaryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        op;
        left;
        right;
        withPar = true; %with parentheses
        addEpsilon = false;
        epsilon = [];
        operandsDT = ''; % operands DataType
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
        % if you add more prelude operators. Update funciton "hasPreludeOperator"
        % in "print_lustrec.m" in "nasa_toLustre.lustreAst.LustreProgram"
        PRELUDE_MULTIPLY = '*^';
        PRELUDE_DIVIDE = '/^';
        PRELUDE_OFFSET = '~>';
        PRELUDE_FBY = 'fby';
    end
    methods
        %%
        function obj = BinaryExpr(op, left, right, withPar, addEpsilon, epsilon, operandsDT)
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
            if nargin < 4 || isempty(withPar)
                obj.withPar = true;
            else
                obj.withPar = withPar;
            end
            if nargin < 5 || isempty(addEpsilon)
                obj.addEpsilon = false;
            else
                obj.addEpsilon = addEpsilon;
            end
            if nargin < 6 || isempty(epsilon)
                obj.epsilon = [];
            else
                obj.epsilon = epsilon;
            end
            if nargin < 7 || isempty(operandsDT)
                obj.operandsDT = '';
                if isa(obj.left, 'nasa_toLustre.lustreAst.RealExpr') ...
                        || isa(obj.right, 'nasa_toLustre.lustreAst.RealExpr')
                    obj.operandsDT = 'real';
                end
            else
                obj.operandsDT = operandsDT;
            end
            % check the object is a valid Lustre AST.
            if ~isa(obj.left, 'nasa_toLustre.lustreAst.LustreExpr') ...
                    || ~isa(obj.right, 'nasa_toLustre.lustreAst.LustreExpr')
                ME = MException('COCOSIM:LUSTREAST', ...
                    'BinaryExpr ERROR: Expected parameters of type LustreExpr. Left operand of class "%s" and Right operand of class "%s".',...
                    class(obj.left), class(obj.right));
                throw(ME);
            end
        end
        
        setPar(obj, withPar)
        function setOperandsDT(obj, dt)
            obj.operandsDT = dt;
        end
        %% deepCopy
        new_obj = deepCopy(obj)
        
        %% substituteVars
        new_obj = substituteVars(obj, oldVar, newVar)
        
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.left}; obj.left.getAllLustreExpr();...
                {obj.right}; obj.right.getAllLustreExpr()];
        end
        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOcc
        nb_occ = nbOccuranceVar(obj, var)
        
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        
        new_obj = changeArrowExp(obj, cond)
        
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = [obj.left.GetVarIds(), obj.right.GetVarIds()];
        end
        
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
        
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
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        
        code = print_zustre(obj)
        
        code = print_jkind(obj)
        
        code = print_prelude(obj)
        
    end
    
    
    methods(Static)
        % Given many args, this function return the binary operation
        % applied on all arguments.
        function exp = BinaryMultiArgs(op, args, operandsDT, isFirstTime)
            
            
            if nargin < 4 || isempty(isFirstTime)
                isFirstTime = 1;
            end
            if nargin < 3 || isempty(operandsDT)
                operandsDT = '';
            end
            if isempty(args) || numel(args) == 1
                if iscell(args)
                    exp = args{1};
                else
                    exp = args;
                end
            elseif numel(args) == 2
                exp = nasa_toLustre.lustreAst.BinaryExpr(op, ...
                    args{1}, ...
                    args{2},...
                    false);
                if ~isempty(operandsDT)
                    exp.setOperandsDT(operandsDT);
                end
                
            else
                exp = nasa_toLustre.lustreAst.BinaryExpr(op, ...
                    args{1}, ...
                    nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, args(2:end), operandsDT, false), ...
                    false);
                if ~isempty(operandsDT)
                    exp.setOperandsDT(operandsDT);
                end
                
            end
            if isFirstTime && isa(exp, 'nasa_toLustre.lustreAst.BinaryExpr')
                exp.setPar(true);
            end
            
        end
    end
end

