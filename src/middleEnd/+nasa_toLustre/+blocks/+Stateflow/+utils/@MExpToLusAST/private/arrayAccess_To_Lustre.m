function [code, exp_dt] = arrayAccess_To_Lustre(obj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function should be only called from fun_indexing_To_Lustre.m
    %Array access
    
    exp_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
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
    namesAst = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.ID_To_Lustre(obj, tree.ID, parent, blk, data_map, ...
        inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
    
    if numel(tree.parameters) == 1
        %Vector Access
        if iscell(tree.parameters)
            param = tree.parameters{1};
        else
            param = tree.parameters;
        end
        param_type = param.type;
        if strcmp(param_type, 'constant')
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
            [arg, ~, ~] = ...
                nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(obj, tree.parameters, ...
                parent, blk, data_map, inputs, params_dt, isSimulink,...
                isStateFlow, isMatlabFun);
            for argIdx=1:numel(arg)
                if isa(arg{argIdx}, 'nasa_toLustre.lustreAst.IntExpr')
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
                        conds{i} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, arg{argIdx}, nasa_toLustre.lustreAst.IntExpr(i));
                        thens{i} = namesAst{i};
                    end
                    thens{n} = namesAst{n};
                    code{argIdx} = nasa_toLustre.lustreAst.ParenthesesExpr(nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
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
                    nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(obj, parameters{i}, ...
                    parent, blk, data_map, inputs, params_dt, isSimulink,...
                    isStateFlow, isMatlabFun);
            end
            
            idx = args{1};
            for i=2:numel(parameters)
                v = args{i};
                idx = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                    idx,...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, v, nasa_toLustre.lustreAst.IntExpr(1)),...
                    nasa_toLustre.lustreAst.IntExpr(prod(CompiledSize(1:i-1)))));
            end
            n = numel(namesAst);
            conds = cell(n-1, 1);
            thens = cell(n, 1);
            for i=1:n-1
                conds{i} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, idx, nasa_toLustre.lustreAst.IntExpr(i));
                thens{i} = namesAst{i};
            end
            thens{n} = namesAst{n};
            code = nasa_toLustre.lustreAst.ParenthesesExpr(nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
        end
    end
end
