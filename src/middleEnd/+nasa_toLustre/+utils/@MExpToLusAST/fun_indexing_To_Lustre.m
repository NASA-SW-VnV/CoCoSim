function [code, exp_dt, dim] = fun_indexing_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    tree_ID = tree.ID;
    dim = [];
    switch tree_ID
        case  {'acos', 'acosh', 'asin', 'asinh', 'atan', ...
                'atanh', 'cbrt', 'cos', 'cosh',...
                'sqrt', 'exp', 'log', 'log10',...
                'sin','tan', 'sinh', 'trunc', ...
                'atan2', 'power', 'pow', ...
                'hypot', 'abs', 'sgn', 'sign', ...
                'rem', 'mod'}
            
            [code, exp_dt, dim] = mathFun_To_Lustre(tree, args);
            
        case {'ceil', 'floor', 'round', 'fabs', ...
                'int8', 'int16', 'int32', ...
                'uint8', 'uint16', 'uint32', ...
                'double', 'single', 'boolean'}
            [code, exp_dt, dim] = convFun_To_Lustre(tree, args);
            
        case {'or', 'and', 'xor', 'plus', 'minus'}
            [code, exp_dt, dim] = binaryFun_To_Lustre(tree, args);
            
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
                [code, exp_dt, dim] = func_handle(tree, args);
            catch me
                if strcmp(me.identifier, 'MATLAB:UndefinedFunction')
                    code = parseOtherFunc(tree, args);
                    dim = [1 1];
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.fun_indexing_To_Lustre', '');
                    ME = MException('COCOSIM:TREE2CODE', ...
                        'Parser ERROR for function "%s" in Expression "%s"',...
                        tree_ID, tree.text);
                    throw(ME);
                end
            end
    end
    
end



function code = parseOtherFunc(tree, args)
    global SF_MF_FUNCTIONS_MAP;
    
    if (args.isStateFlow || args.isMatlabFun) && args.data_map.isKey(tree.ID)
        %Array Access
        code = arrayAccess_To_Lustre(tree, args);
        
    elseif (args.isStateFlow || args.isMatlabFun) && SF_MF_FUNCTIONS_MAP.isKey(tree.ID)
        %Stateflow Function and Matlab Function block
        code = sf_mf_functionCall_To_Lustre(tree, args);
        
    elseif args.isSimulink && strcmp(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if strcmp(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            code = args.inputs{1}{input_idx};
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'expression "%s" is not supported in block "%s"', ...
                tree.text, args.blk.Origin_path);
            throw(ME);
        end
        
    elseif args.isSimulink &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if strcmp(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            code = args.inputs{input_number}{arrayIndex};
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'expression "%s" is not supported in block "%s"', ...
                tree.text, args.blk.Origin_path);
            throw(ME);
        end
    else
        try
            % eval in base expression such as
            % A(1,1) or single(1e-18) ...
            exp = tree.text;
            [value, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(args.parent, args.blk, exp);
            if status
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s" or in workspace', ...
                    exp, args.blk.Origin_path);
                throw(ME);
            end
            if strcmp(args.expected_lusDT, 'real') ...
                    || isempty(args.expected_lusDT)
                code = nasa_toLustre.lustreAst.RealExpr(value);
            elseif strcmp(args.expected_lusDT, 'bool')
                code = nasa_toLustre.lustreAst.BooleanExpr(value);
            else
                code = nasa_toLustre.lustreAst.IntExpr(value);
            end
        catch
            
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, args.blk.Origin_path);
            throw(ME);
            
        end
    end
    % we need this function to return a cell.
    if ~iscell(code)
        code = {code};
    end
end






