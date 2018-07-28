classdef LustreContract < LustreAst
    %LustreContract
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        metaInfo;%String
        name; %String
        inputs; %list of Vars
        outputs;
        localVars;
        localEqs;
    end
    
    methods 
        function obj = LustreContract(metaInfo, name, inputs, ...
                outputs, localVars, localEqs)
            obj.metaInfo = metaInfo;
            obj.name = name;
            obj.inputs = inputs;
            obj.outputs = outputs;
            obj.localVars = localVars;
            obj.localEqs = localEqs;
        end
        function dt = getDT(localVars, varID)
            dt = '';
            for i=1:numel(localVars)
                if isequal(localVars{i}.id, varID)
                    dt = localVars{i}.type;
                    break;
                end
            end
        end
        
        function code = print(obj, backend)
            %TODO: check if KIND2 syntax is OK for the other backends.
            code = obj.print_kind2(backend);
        end
        
        function code = print_lustrec(obj)
            code = '';
        end
        
        function code = print_kind2(obj, backend)
            lines = {};
            if ~isempty(obj.metaInfo)
                lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                    obj.metaInfo);
            end
            lines{end + 1} = sprintf('contract %s(%s)\nreturns(%s);\n', ...
                obj.name, ...
                LustreAst.listVarsWithDT(obj.inputs), ...
                LustreAst.listVarsWithDT(obj.outputs));
            lines{end+1} = 'let\n';
            % local Eqs
            for i=1:numel(obj.localEqs)
                eq = obj.localEqs{i};
                if ~isa(eq, 'LustreEq')
                    % assumptions, guarantees, modes...
                    lines{end+1} = sprintf('\t%s\n', ...
                        eq.print(backend));
                    continue;
                end
                if numel(eq.lhs) > 1
                    var = eq.lhs{1};
                else 
                    var = eq.lhs;
                end
                if ~isa(var, 'LustreVar')
                    continue;
                end
                varDT = getDT(obj.localVars, var.id);
                
                lines{end+1} = sprintf('\tvar %s : %s = %s;\n', ...
                        var.id, varDT, eq.rhs.print(backend));
            end
            lines{end+1} = 'tel\n';
            code = MatlabUtils.strjoin(lines, '');
        end
        function code = print_zustre(obj)
            code = '';
        end
        function code = print_jkind(obj)
            code = '';
        end
        function code = print_prelude(obj)
            code = '';
        end
    end

end

