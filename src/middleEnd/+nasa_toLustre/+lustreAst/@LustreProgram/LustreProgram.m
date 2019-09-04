classdef LustreProgram < nasa_toLustre.lustreAst.LustreAst
    %LustreProgram
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        types;
        opens;
        nodes;
        contracts;
    end
    
    methods
        function obj = LustreProgram(opens, types, nodes, contracts)
            if iscell(types)
                obj.types = types;
            else
                obj.types{1} = types;
            end
            if iscell(opens)
                obj.opens = opens;
            else
                obj.opens{1} = opens;
            end
            if iscell(nodes)
                obj.nodes = nodes;
            else
                obj.nodes{1} = nodes;
            end
            if iscell(contracts)
                obj.contracts = contracts;
            else
                obj.contracts{1} = contracts;
            end
        end
        
        new_obj = deepCopy(obj)
        
        new_obj = simplify(obj)
        
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, ~)
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, varargin)
       
        %% nbOccuranceVar is used within a node
        nb_occ = nbOccuranceVar(varargin)
        
        %%
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
        
        [lines, alreadyPrinted] = printWithOrder(obj, ...
                nodesList, nodeName, call_map, alreadyPrinted, lines, backend)
    end
    
end

