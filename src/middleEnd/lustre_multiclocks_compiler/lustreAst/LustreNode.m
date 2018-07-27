classdef LustreNode < LustreAst
    %LustreNode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;%String
        inputs;
        outputs;
        localContract;
        localVars;
        bodyEqs;
        isMain;
    end
    
    methods
        function obj = LustreNode(name, inputs, outputs, ...
                localContract, localVars, bodyEqs, isMain)
            obj.name = name;
            obj.inputs = inputs;
            obj.outputs = outputs;
            obj.localContract = localContract;
            obj.localVars = localVars;
            obj.bodyEqs = bodyEqs;
            obj.isMain = isMain;
        end
        
        
        function code = print_lustrec(obj)
            lines = {};
            lines{1} = sprintf('node %s(%s)\nreturns(%s);\n', ...
                obj.name, ...
                LustreAst.listVarsWithDT(obj.inputs), ...
                LustreAst.listVarsWithDT(obj.outputs));
            if ~isempty(obj.localContract)
                lines{end + 1} = obj.localContract.print_lustre();
            end
            if ~isempty(obj.localVars)
                lines{end + 1} = sprintf('var %s', ...
                    LustreAst.listVarsWithDT(obj.localVars));
            end
            lines{end+1} = 'let\n';
            % local Eqs
            for i=1:numel(obj.bodyEqs)
                eq = obj.bodyEqs{i};
                lines{end+1} = sprintf('\t%s\n', ...
                    eq.print_lustrec());
            end
            lines{end+1} = 'tel\n';
            code = MatlabUtils.strjoin(lines, '');
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
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

