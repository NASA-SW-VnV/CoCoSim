classdef ContractModeExpr < LustreExpr
    %ContractGuaranteeExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name; %String
        requires; %LustreExp[]
        ensures; %LustreExp[]
    end
    
    methods
        function obj = ContractModeExpr(name, requires, ensures)
            obj.name = name;
            obj.requires = requires;
            obj.ensures = ensures;
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.requires)
                new_requires = cellfun(@(x) x.deepCopy(), obj.requires, ...
                    'UniformOutput', 0);
            else
                new_requires = obj.requires.deepCopy();
            end
            if iscell(obj.ensures)
                new_ensures = cellfun(@(x) x.deepCopy(), obj.ensures, ...
                    'UniformOutput', 0);
            else
                new_ensures = obj.ensures.deepCopy();
            end
            new_obj = ContractModeExpr(obj.name, new_requires, new_ensures);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        %%
        function code = print(obj, backend)
            if BackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                code = '';
            end
        end
        
        function code = print_lustrec(obj)
            code = '';
        end
        function code = print_kind2(obj, backend)
            require = {};
            for j=1:numel(obj.requires)
                require{j} = sprintf('\t\trequire %s;\n', ...
                    obj.requires{j}.print(backend));
            end
            require = MatlabUtils.strjoin(require, '');
            
            ensure = {};
            for j=1:numel(obj.ensures)
                ensure{j} = sprintf('\t\tensure %s;\n', ...
                    obj.ensures{j}.print(backend));
            end
            ensure = MatlabUtils.strjoin(ensure, '');
            code = sprintf('\tmode %s(\n%s%s\t);\n', obj.name, require, ensure);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec();
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec();
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec();
        end
    end
    
end

