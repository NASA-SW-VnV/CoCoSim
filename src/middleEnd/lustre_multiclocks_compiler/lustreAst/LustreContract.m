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
        
        function new_obj = deepCopy(obj)
             if iscell(obj.inputs)
                new_inputs = cellfun(@(x) x.deepCopy(), obj.inputs, ...
                    'UniformOutput', 0);
            else
                new_inputs = obj.inputs.deepCopy();
            end
            if iscell(obj.outputs)
                new_outputs = cellfun(@(x) x.deepCopy(), obj.outputs,...
                    'UniformOutput', 0);
            else
                new_outputs = obj.outputs.deepCopy();
            end
            if iscell(obj.localVars)
                new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, ...
                    'UniformOutput', 0);
            else
                new_localVars = obj.localVars.deepCopy();
            end
            if iscell(obj.localEqs)
                new_localEqs = cellfun(@(x) x.deepCopy(), obj.localEqs, ...
                    'UniformOutput', 0);
            else
                new_localEqs = obj.localEqs.deepCopy();
            end
            new_obj = LustreContract(obj.metaInfo, obj.name,...
                new_inputs, ...
                new_outputs, new_localVars, new_localEqs, ...
                obj.islocalContract);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %%
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
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                if iscell(objects)
                    for i=1:numel(objects)
                        nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                    end
                else
                    nodesCalled = [nodesCalled, objects.getNodesCalled()];
                end
            end
            addNodes(obj.localEqs);
        end
        
        %%
        function code = print(obj, backend)
            if BackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                code = '';
            end
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

