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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef LustreEq < nasa_toLustre.lustreAst.LustreExpr
    %LustreEq

    properties
        lhs;
        rhs;
    end
    
    methods
        function obj = LustreEq(lhs, rhs)
            if ischar(rhs)
                obj.rhs = nasa_toLustre.lustreAst.VarIdExpr(rhs);
            elseif iscell(rhs) && numel(rhs) == 1
                obj.rhs = rhs{1};
            elseif iscell(rhs)
                obj.rhs = nasa_toLustre.lustreAst.TupleExpr(rhs);
            else
                obj.rhs = rhs;
            end
            if ischar(lhs)
                obj.lhs = nasa_toLustre.lustreAst.VarIdExpr(lhs);
            elseif iscell(lhs) && numel(lhs) == 1
                obj.lhs = lhs{1};
            elseif iscell(lhs)
                obj.lhs = nasa_toLustre.lustreAst.TupleExpr(lhs);
            else
                obj.lhs = lhs;
            end
        end
        function lhs = getLhs(obj)
            lhs = obj.lhs;
        end
        function rhs = getRhs(obj)
            rhs = obj.rhs;
        end
        %%
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOcc
        nb_occ = nbOccuranceVar(obj, var)
        %% substituteVars
        new_obj = substituteVars(obj, oldVar, newVar, substitueLeft)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.lhs; obj.rhs}; obj.lhs.getAllLustreExpr();...
                obj.rhs.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        
        new_obj = changeArrowExp(obj, cond)
        
        %% Stateflow function
        function [outputs, inputs] = GetVarIds(obj)
            outputs = obj.lhs.GetVarIds();
            inputs = obj.rhs.GetVarIds();
        end
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.rhs);
        end
        
        
        %%
        code = print(obj, backend)
        
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

