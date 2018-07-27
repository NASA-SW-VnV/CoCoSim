classdef LustreContract < LustreAst
    %LustreContract
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name; %String
        inputs; %list of Vars
        outputs;
        assumptions;
        guarantees;
        localVars;
        localEqs;
        modes;
    end
    
    methods 
        function obj = LustreContract(name, inputs, outputs, assumptions,...
                guarantees, localVars, localEqs, modes)
            obj.name = name;
            obj.inputs = inputs;
            obj.outputs = outputs;
            obj.assumptions = assumptions;
            obj.guarantees = guarantees;
            obj.localVars = localVars;
            obj.localEqs = localEqs;
            obj.modes = modes;
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
        
        function code = print_lustrec(obj)
            code = '';
        end
        
        function code = print_kind2(obj)
            lines = {};
            lines{1} = sprintf('contract %s(%s)\nreturns(%s);\n', ...
                obj.name, ...
                LustreAst.listVarsWithDT(obj.inputs), ...
                LustreAst.listVarsWithDT(obj.outputs));
            lines{end+1} = 'let\n';
            % local Eqs
            for i=1:numel(obj.localEqs)
                eq = obj.localEqs{i};
                if ~isa(eq, 'LustreEq')
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
                        var.id, varDT, eq.rhs.print_kind2());
            end
            % assumptions
            for i=1:numel(obj.assumptions)
                lines{end+1} = sprintf('\t%s\n', ...
                    obj.assumptions{i}.print_kind2());
            end
            % guarantees
            for i=1:numel(obj.guarantees)
                lines{end+1} = sprintf('\t%s\n', ...
                    obj.guarantees{i}.print_kind2());
            end
            % modes
            for i=1:numel(obj.modes)
                lines{end+1} = sprintf('\t%s\n', ...
                    obj.modes{i}.print_kind2());
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

