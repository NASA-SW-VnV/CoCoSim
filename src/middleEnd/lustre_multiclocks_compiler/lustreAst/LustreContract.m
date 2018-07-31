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
        islocalContract;
    end
    
    methods
        function obj = LustreContract(metaInfo, name, inputs, ...
                outputs, localVars, localEqs, islocalContract)
            if nargin == 0
                obj.metaInfo = '';
                obj.name = '';
                obj.inputs = {};
                obj.outputs = {};
                obj.localVars = {};
                obj.localEqs = {};
                obj.islocalContract = 1;
            else
                obj.metaInfo = metaInfo;
                obj.name = name;
                obj.inputs = inputs;
                obj.outputs = outputs;
                obj.localVars = localVars;
                obj.localEqs = localEqs;
                obj.islocalContract = islocalContract;
            end
        end
        
        function setBody(obj, localEqs)
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
                if ischar(obj.metaInfo)
                    lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                        obj.metaInfo);
                else
                    lines{end + 1} = obj.metaInfo.print(backend);
                end
            end
            if obj.islocalContract
                lines{end+1} = '(*@contract\n';
                lines = obj.getLustreEq( lines, backend);
                lines{end+1} = '*)\n';
            else
                lines{end + 1} = sprintf('contract %s(%s)\nreturns(%s);\n', ...
                    obj.name, ...
                    LustreAst.listVarsWithDT(obj.inputs, backend), ...
                    LustreAst.listVarsWithDT(obj.outputs, backend));
                lines{end+1} = 'let\n';
                % local Eqs
                lines = obj.getLustreEq( lines, backend);
                lines{end+1} = 'tel\n';
            end
            code = sprintf(MatlabUtils.strjoin(lines, ''));
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
        
        %% utils
        function lines = getLustreEq(obj, lines, backend)
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
        end
    end
    
end

