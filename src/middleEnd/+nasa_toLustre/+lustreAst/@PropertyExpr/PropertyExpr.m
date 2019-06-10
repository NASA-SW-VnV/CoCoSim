classdef PropertyExpr < nasa_toLustre.lustreAst.LustreExpr
    %PropertyExpr: This class will be the base class for LocalProperty,
    %AssertExpr, Gurantee, Assume
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    properties
        id; %String
        exp; %LustreExp
    end
    
    methods(Abstract)
        new_obj = deepCopy(obj)
        code = print(obj, backend)
        code = print_lustrec(obj, backend)
        code = print_kind2(obj, backend)
        code = print_zustre(obj, backend)
        code = print_jkind(obj, backend)
        code = print_prelude(obj)
    end
    methods
        function obj = PropertyExpr(id, exp)
            obj.id = id;
            if iscell(exp)
                obj.exp = exp{1};
            else
                obj.exp = exp;
            end
        end
        
        
        %% simplify expression
        function obj = simplify(obj)
            obj.exp = obj.exp.simplify();
        end
        
        %% nbOccurance
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.exp.nbOccuranceVar(var);
        end
        
        
        %% substituteVars
        function obj = substituteVars(obj, oldVar, newVar)
            obj.exp = obj.exp.substituteVars(oldVar, newVar);
        end
        
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.exp}; obj.exp.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = obj.exp.GetVarIds;
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.exp);
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            [obj.exp, outputs_map] = obj.exp.pseudoCode2Lustre(outputs_map, isLeft);
        end
        
        
    end
    
end

