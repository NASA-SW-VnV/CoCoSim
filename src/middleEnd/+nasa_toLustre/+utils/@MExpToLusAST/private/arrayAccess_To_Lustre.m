%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [code, exp_dt, dim, extra_code] = arrayAccess_To_Lustre(tree, args)

    
    % This function should be only called from fun_indexing_To_Lustre.m
    %Array access
    code = {};
    extra_code = {};
    exp_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    
    params_dt = 'int';
    [namesAst, ~, CompiledSize] = nasa_toLustre.utils.MExpToLusAST.ID_To_Lustre(tree.ID, args);
    if numel(CompiledSize) < numel(tree.parameters)
        ME = MException('COCOSIM:TREE2CODE', ...
            'Data Access "%s" expected %d parameters but got %d',...
            tree.text, numel(CompiledSize), numel(tree.parameters));
        throw(ME);
    end
    
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
            dim = [1 1];
            if iscell(namesAst) && numel(namesAst) >= value
                code{1} = namesAst{value};
            else
                ME = MException('COCOSIM:TREE2CODE', ...
                    'ParseError of "%s"',...
                    tree.text);
                throw(ME);
            end
        else
            args.expected_lusDT = params_dt;
            args.end_value = prod(CompiledSize);
            [arg, ~, arg_dim, extra_code] = ...
                nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters, args);
            
            if endsWith(args.data_map(tree.ID).ArraySize, '  1')
                dim = [arg_dim(2) arg_dim(1)];
            else
                dim = arg_dim;
            end
            
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
                    code{argIdx} = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
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
            dim = [1 1];
            code{1} = constantIndexing(namesAst, parameters, CompiledSize, tree);
        else
            %e.g., A(1:end, 2) , H(:,j)
            cell_params = cell(numel(parameters), 1);
            args.expected_lusDT = params_dt;
            for i=1:length(parameters)
                if length(CompiledSize) == length(parameters)
                    args.end_value = CompiledSize(i);
                elseif i == length(parameters)
                    args.end_value = prod(CompiledSize(i:end));
                else
                    args.end_value = CompiledSize(i);
                end
                [cell_params{i}, ~, ~, extra_code_i] = ...
                    nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(parameters{i}, args);
                extra_code = MatlabUtils.concat(extra_code, extra_code_i);
            end
            dim = arrayfun(@(i) length(cell_params{i}), 1:length(cell_params));
            params_list = MatlabUtils.cellCartesianProduct(cell_params);
            [nbR, ~] = size(params_list);
            for pidx = 1:nbR
                params = params_list(pidx, :);
                params_type = cellfun(@(x) class(x), params, 'UniformOutput', false);
                isConstant = all(strcmp(params_type, 'nasa_toLustre.lustreAst.IntExpr'));
                if isConstant
                    code{pidx} = constantIndexing(namesAst, params, CompiledSize, tree);
                else
                    idx = params{1};
                    for i=2:numel(params)
                        v = params{i};
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
                    code{pidx} = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
                end
            end
        end
    end
end
function code = constantIndexing(namesAst, parameters, CompiledSize, tree)
    % parameters can be a list of "nasa_toLustre.lustreAst.IntExpr" or a list
    % of structurs from Matlab Java parser of type "constant".
    code = {};
    if ischar(parameters{1}.value)
        idx = str2double(parameters{1}.value);
    else
        idx = parameters{1}.value;
    end
    for i=2:numel(parameters)
        if ischar(parameters{i}.value)
            v = str2double(parameters{i}.value);
        else
            v = parameters{i}.value;
        end
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
end