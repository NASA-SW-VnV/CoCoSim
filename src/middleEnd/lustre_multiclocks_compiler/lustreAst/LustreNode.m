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
            if nargin==0
                obj.metaInfo = '';
                obj.name = '';
                obj.inputs = {};
                obj.outputs = {};
                obj.localContract = {};
                obj.localVars = {};
                obj.bodyEqs = {};
                obj.isMain = false;
            else
                obj.metaInfo = metaInfo;
                obj.name = name;
                obj.inputs = inputs;
                obj.outputs = outputs;
                obj.localContract = localContract;
                obj.localVars = localVars;
                obj.bodyEqs = bodyEqs;
                obj.isMain = isMain;
            end
        end
        function setName(obj, name)
            obj.name = name;
        end
        function setInputs(obj, inputs)
            obj.inputs = inputs;
        end
        function setOutputs(obj, outputs)
            obj.outputs = outputs;
        end
        function setLocalContract(obj, localContract)
            obj.localContract = localContract;
        end
        function setLocalVars(obj, localVars)
            obj.localVars = localVars;
        end
        function setBodyEqs(obj, bodyEqs)
            obj.bodyEqs = bodyEqs;
        end
        function setIsMain(obj, isMain)
            obj.isMain = isMain;
        end
        
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            lines = {};
            if ~isempty(obj.metaInfo)
                if ischar(obj.metaInfo)
                    lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                        obj.metaInfo);
                else
                    lines{end + 1} = obj.metaInfo.print(backend);
                end
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
            if iscell(obj.bodyEqs)
                for i=1:numel(obj.bodyEqs)
                    eq = obj.bodyEqs{i};
                    lines{end+1} = sprintf('\t%s\n', ...
                        eq.print(backend));
                end
            elseif ~isempty(obj.bodyEqs)
                lines{end+1} = sprintf('\t%s\n', ...
                    obj.bodyEqs.print(backend));
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

