function [code, exp_dt] = fun_indexing_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    tree_ID = tree.ID;
    switch tree_ID
        case  {'acos', 'acosh', 'asin', 'asinh', 'atan', ...
                'atanh', 'cbrt', 'cos', 'cosh',...
                'sqrt', 'exp', 'log', 'log10',...
                'sin','tan', 'sinh', 'trunc', ...
                'atan2', 'power', 'pow', ...
                'hypot', 'abs', 'sgn', ...
                'rem', 'mod'}
            
            [code, exp_dt] = mathFun_To_Lustre(BlkObj, tree, parent, blk,...
                data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
            
        case {'ceil', 'floor', 'round', 'fabs', ...
                'int8', 'int16', 'int32', ...
                'uint8', 'uint16', 'uint32', ...
                'double', 'single', 'boolean'}
            [code, exp_dt] = convFun_To_Lustre(BlkObj, tree, parent, blk,...
                data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
            
        case {'disp', 'sprintf', 'fprintf', 'plot'}
            %ignore these printing functions
            code = {};
            exp_dt = '';
            
        otherwise
            try
                % case of : "all", "any" and other functions defined in private folder.
                %cocosim2/src/middleEnd/+nasa_toLustre/+blocks/+Stateflow/+utils/@MExpToLusAST/private
                func_name = strcat(tree_ID, 'Fun_To_Lustre');
                func_handle = str2func(func_name);
                [code, exp_dt] = func_handle(BlkObj, tree, parent, blk, ...
                    data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
            catch
                code = parseOtherFunc(BlkObj, tree, ...
                    parent, blk, data_map, inputs, ...
                    expected_dt, isSimulink, isStateFlow, isMatlabFun);
            end
    end
    
end



function code = parseOtherFunc(obj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    global SF_GRAPHICALFUNCTIONS_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    if ~isSimulink && data_map.isKey(tree.ID)
        %Array Access
        code = arrayAccess_To_Lustre(obj, tree, parent, blk, ...
            data_map, inputs,  expected_dt, isSimulink, isStateFlow, isMatlabFun);
        
    elseif isStateFlow && SF_GRAPHICALFUNCTIONS_MAP.isKey(tree.ID)
        %Stateflow Function
        code = sfGraphFunction_To_Lustre(obj, tree, parent, blk, ...
            data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
        
    elseif isSimulink && isequal(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if isequal(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            code = inputs{1}{input_idx};
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'expression "%s" is not supported in block "%s"', ...
                tree.text, blk.Origin_path);
            throw(ME);
        end
        
    elseif isSimulink &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if isequal(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            code = inputs{input_number}{arrayIndex};
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'expression "%s" is not supported in block "%s"', ...
                tree.text, blk.Origin_path);
            throw(ME);
        end
    else
        try
            % eval in base expression such as
            % A(1,1) or single(1e-18) ...
            exp = tree.text;
            [value, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, exp);
            if status
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s" or in workspace', ...
                    exp, blk.Origin_path);
                throw(ME);
            end
            if strcmp(expected_dt, 'real') ...
                    || isempty(expected_dt)
                code = RealExpr(value);
            elseif strcmp(expected_dt, 'bool')
                code = BooleanExpr(value);
            else
                code = IntExpr(value);
            end
        catch
            
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, blk.Origin_path);
            throw(ME);
            
        end
    end
    % we need this function to return a cell.
    if ~iscell(code)
        code = {code};
    end
end






