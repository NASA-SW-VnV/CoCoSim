classdef LustreNode < LustreAst
    %LustreNode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        metaInfo;%String
        name;%String
        inputs;
        outputs;
        localContract;
        localVars;
        bodyEqs;
        isMain;
    end
    
    methods
        function obj = LustreNode(metaInfo, name, inputs, outputs, ...
                localContract, localVars, bodyEqs, isMain)
            obj.metaInfo = metaInfo;
            obj.name = name;
            obj.inputs = inputs;
            obj.outputs = outputs;
            obj.localContract = localContract;
            obj.localVars = localVars;
            obj.bodyEqs = bodyEqs;
            obj.isMain = isMain;
        end
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            lines = {};
            if ~isempty(obj.metaInfo)
                lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                    obj.metaInfo);
            end
            lines{end + 1} = sprintf('node %s(%s)\nreturns(%s);\n', ...
                obj.name, ...
                LustreAst.listVarsWithDT(obj.inputs, backend), ...
                LustreAst.listVarsWithDT(obj.outputs, backend));
            if ~isempty(obj.localContract)
                lines{end + 1} = obj.localContract.print(backend);
            end
            if ~isempty(obj.localVars)
                lines{end + 1} = sprintf('var %s\n', ...
                    LustreAst.listVarsWithDT(obj.localVars, backend));
            end
            lines{end+1} = sprintf('let\n');
            % local Eqs
            for i=1:numel(obj.bodyEqs)
                eq = obj.bodyEqs{i};
                lines{end+1} = sprintf('\t%s\n', ...
                    eq.print(backend));
            end
            lines{end+1} = sprintf('tel\n');
            code = MatlabUtils.strjoin(lines, '');
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
    
end

