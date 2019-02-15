function [code, exp_dt] = arrayAccess_To_Lustre(obj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function should be only called from fun_indexing_To_Lustre.m
    %Array access
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    exp_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    d = data_map(tree.ID);
    if isfield(d, 'CompiledSize')
        CompiledSize = str2num(d.CompiledSize);
    elseif isfield(d, 'ArraySize')
        CompiledSize = str2num(d.ArraySize);
    else
        CompiledSize = -1;
    end
    if CompiledSize == -1
        ME = MException('COCOSIM:TREE2CODE', ...
            'Data "%s" has unknown ArraySize',...
            tree.ID);
        throw(ME);
    end
    if numel(CompiledSize) < numel(tree.parameters)
        ME = MException('COCOSIM:TREE2CODE', ...
            'Data Access "%s" expected %d parameters but got %d',...
            tree.text, numel(CompiledSize), numel(tree.parameters));
        throw(ME);
    end
    params_dt = 'int';
    namesAst = MExpToLusAST.ID_To_Lustre(obj, tree.ID, parent, blk, data_map, ...
        inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
    
    if numel(tree.parameters) == 1
        %Vector Access
        if iscell(tree.parameters)
            param = tree.parameters{1};
        else
            param = tree.parameters;
        end
        param_type = param.type;
        if isequal(param_type, 'constant')
            value = str2num(param.value);
            
            if iscell(namesAst) && numel(namesAst) >= value
                code = namesAst{value};
            else
                ME = MException('COCOSIM:TREE2CODE', ...
                    'ParseError of "%s"',...
                    tree.text);
                throw(ME);
            end
        else
            [arg, ~] = ...
                MExpToLusAST.expression_To_Lustre(obj, tree.parameters, ...
                parent, blk, data_map, inputs, params_dt, isSimulink,...
                isStateFlow, isMatlabFun);
            for argIdx=1:numel(arg)
                if isa(arg{argIdx}, 'IntExpr')
                    value = arg{argIdx}.getValue();
                    if iscell(namesAst) && numel(namesAst) >= value
                        code{argIdx} = namesAst{value};
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'ParseError of "%s"',...
                            tree.text);
                        throw(ME);
                    end
                else
                    n = numel(namesAst);
                    conds = cell(n-1, 1);
                    thens = cell(n, 1);
                    for i=1:n-1
                        conds{i} = BinaryExpr(BinaryExpr.EQ, arg{argIdx}, IntExpr(i));
                        thens{i} = namesAst{i};
                    end
                    thens{n} = namesAst{n};
                    code{argIdx} = ParenthesesExpr(IteExpr.nestedIteExpr(conds, thens));
                end
            end
        end
    else
        %multi-dimension access
        if isa(tree.parameters, 'struct')
            parameters = arrayfun(@(x) x, tree.parameters, 'UniformOutput', false);
            params_type = arrayfun(@(x) x.type, tree.parameters, 'UniformOutput', false);
        else
            parameters = tree.parameters;
            params_type = cellfun(@(x) x.type, tree.parameters, 'UniformOutput', false);
        end
        isConstant = all(strcmp(params_type, 'constant'));
        if isConstant
            %[n,m,l] = size(M)
            %idx = i + (j-1) * n + (k-1) * n * m
            idx = str2num(parameters{1}.value);
            for i=2:numel(parameters)
                v = str2num(parameters{i}.value);
                idx = idx + (v - 1) * prod(CompiledSize(1:i-1));
            end
            if iscell(namesAst) && numel(namesAst) >= idx
                code = namesAst{idx};
            else
                ME = MException('COCOSIM:TREE2CODE', ...
                    'ParseError of "%s"',...
                    tree.text);
                throw(ME);
            end
        else
            args = cell(numel(parameters), 1);
            for i=1:numel(parameters)
                [args(i), ~] = ...
                    MExpToLusAST.expression_To_Lustre(obj, parameters{i}, ...
                    parent, blk, data_map, inputs, params_dt, isSimulink,...
                    isStateFlow, isMatlabFun);
            end
            
            idx = args{1};
            for i=2:numel(parameters)
                v = args{i};
                idx = BinaryExpr(BinaryExpr.PLUS,...
                    idx,...
                    BinaryExpr(BinaryExpr.MULTIPLY,...
                    BinaryExpr(BinaryExpr.MINUS, v, IntExpr(1)),...
                    IntExpr(prod(CompiledSize(1:i-1)))));
            end
            n = numel(namesAst);
            conds = cell(n-1, 1);
            thens = cell(n, 1);
            for i=1:n-1
                conds{i} = BinaryExpr(BinaryExpr.EQ, idx, IntExpr(i));
                thens{i} = namesAst{i};
            end
            thens{n} = namesAst{n};
            code = ParenthesesExpr(IteExpr.nestedIteExpr(conds, thens));
        end
    end
end