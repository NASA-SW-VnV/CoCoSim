classdef NodeCallExpr < nasa_toLustre.lustreAst.LustreExpr
    %NodeCallExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        args;
    end
    
    methods
        function obj = NodeCallExpr(nodeName, args)
            obj.nodeName = nodeName;
            if ~iscell(args)
                obj.args{1} = args;
            else
                obj.args = args;
            end
        end
        
        function args = getArgs(obj)
            args = obj.args;
        end
        function  setArgs(obj, args)
            if ~iscell(args)
                obj.args{1} = args;
            else
                obj.args = args;
            end
        end
        function name = getNodeName(obj)
            name = obj.nodeName;
        end
        
        %%
        function new_obj = deepCopy(obj)
            new_args = cellfun(@(x) x.deepCopy(), obj.args, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            import nasa_toLustre.lustreAst.*
            new_args = cellfun(@(x) x.simplify(), obj.args, 'UniformOutput', 0);
            % remove parentheses from arguments.
            for i=1:numel(new_args)
                if isa(new_args{i}, 'ParenthesesExpr')
                    new_args{i} = new_args{i}.getExp();
                elseif isa(new_args{i}, 'BinaryExpr') || isa(new_args{i}, 'UnaryExpr')
                    new_args{i}.setPar(false);
                end
            end
            new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
        end
        
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.args, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        %% substituteVars
        function obj = substituteVars(obj, var, newVar)
            new_args = cellfun(@(x) x.substituteVars(var, newVar), obj.args, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.args)
                all_obj = [all_obj; {obj.args{i}}; obj.args{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_args = cell(numel(obj.args), 1);
            for i=1:numel(obj.args)
                [new_args{i}, varIds_i] = obj.args{i}.changePre2Var();
                varIds = [varIds, varIds_i];
            end
            new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            new_args = cellfun(@(x) x.changeArrowExp(cond), obj.args, 'UniformOutput', 0);
            
            new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
        end
        
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {};
            for i=1:numel(obj.args)
                varIds_i = obj.args{i}.GetVarIds();
                varIds = [varIds, varIds_i];
            end
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_args = cellfun(@(x) x.pseudoCode2Lustre(outputs_map, false),...
                obj.args, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
            end
            addNodes(obj.args);
            nodesCalled{end+1} = obj.nodeName;
        end
        
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            code = sprintf('%s(%s)', ...
                obj.nodeName, ...
               nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.args, backend));
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(LusBackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(LusBackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(LusBackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(LusBackendType.PRELUDE);
        end
    end
    
    methods(Static)
        function args_str = getArgsStr(args, backend)
            %             try
            if numel(args) > 1 || iscell(args)
                if numel(args) >= 1 && iscell(args{1})
                    args_cell = cellfun(@(x) x{1}.print(backend), args, 'UniformOutput', 0);
                else
                    args_cell = cellfun(@(x) x.print(backend), args, 'UniformOutput', 0);
                end
                args_str = MatlabUtils.strjoin(args_cell, ', ');
            elseif numel(args) == 1
                args_str = args.print(backend);
            else
                args_str = '';
            end
            %             catch me
            %                 me
            %             end
        end
    end
end

