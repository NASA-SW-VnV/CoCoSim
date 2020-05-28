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
classdef ContractModeExpr < nasa_toLustre.lustreAst.LustreExpr
    %ContractModeExpr

    properties
        name; %String
        requires; %LustreExp[]
        ensures; %LustreExp[]
    end
    
    methods
        function obj = ContractModeExpr(name, requires, ensures)
            obj.name = name;
            if ~iscell(requires)
                obj.requires{1} = requires;
            else
                obj.requires = requires;
            end
            if ~iscell(ensures)
                obj.ensures{1} = ensures;
            else
                obj.ensures = ensures;
            end
            require_class = unique( cellfun(@(x) class(x), obj.requires, 'UniformOutput', 0));
            ensures_class = unique( cellfun(@(x) class(x), obj.ensures, 'UniformOutput', 0));
            % check the object is a valid Lustre AST.
            if ~( length(require_class) == 1 ...
                    && strcmp(require_class{1}, 'nasa_toLustre.lustreAst.ContractRequireExpr'))
                ME = MException('COCOSIM:LUSTREAST', ...
                    'ContractModeExpr ERROR: Expected second parameter of type "ContractRequireExpr" Got type "%s".',...
                    coco_nasa_utils.MatlabUtils.strjoin(require_class, ', '));
                throw(ME);
            end
            if ~( length(ensures_class) == 1 ...
                    && strcmp(ensures_class{1}, 'nasa_toLustre.lustreAst.ContractEnsureExpr'))
                ME = MException('COCOSIM:LUSTREAST', ...
                    'ContractModeExpr ERROR: Expected third parameter of type "ContractEnsureExpr" Got type "%s".',...
                    coco_nasa_utils.MatlabUtils.strjoin(ensures_class, ', '));
                throw(ME);
            end
        end
        
        new_obj = deepCopy(obj)

        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)

        %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)

        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.requires)
                all_obj = [all_obj; {obj.requires{i}}; obj.requires{i}.getAllLustreExpr()];
            end
            for i=1:numel(obj.ensures)
                all_obj = [all_obj; {obj.ensures{i}}; obj.ensures{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)

        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
            end
            addNodes(obj.requires);
            addNodes(obj.ensures);
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)        
        
        %%
        code = print(obj, backend)

        code = print_lustrec(obj)

        code = print_kind2(obj, backend)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    
end

