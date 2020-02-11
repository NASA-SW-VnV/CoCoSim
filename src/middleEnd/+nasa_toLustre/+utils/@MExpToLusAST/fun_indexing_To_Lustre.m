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
function [code, exp_dt, dim, extra_code] = fun_indexing_To_Lustre(tree, args)

    
    
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    tree_ID = tree.ID;
    dim = [];
    extra_code = {};
    switch tree_ID
        case  {'acos', 'acosh', 'asin', 'asinh', 'atan', ...
                'atanh', 'cbrt', 'cos', 'cosh',...
                'sqrt', 'exp', 'log', 'log10',...
                'sin','tan', 'sinh', 'trunc', ...
                'atan2', 'power', 'pow', ...
                'hypot', 'abs', 'sgn', 'sign', ...
                'rem', 'mod'}
            
            [code, exp_dt, dim, extra_code] = mathFun_To_Lustre(tree, args);
            
        case {'ceil', 'floor', 'round', 'fabs', ...
                'int8', 'int16', 'int32', ...
                'uint8', 'uint16', 'uint32', ...
                'double', 'single', 'boolean'}
            [code, exp_dt, dim, extra_code] = convFun_To_Lustre(tree, args);
            
        case {'or', 'and', 'xor', 'plus', 'minus'}
            [code, exp_dt, dim, extra_code] = binaryFun_To_Lustre(tree, args);
            
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
                [code, exp_dt, dim, extra_code] = func_handle(tree, args);
            catch me
                if strcmp(me.identifier, 'MATLAB:UndefinedFunction')
                    [code, dim, extra_code] = parseOtherFunc(tree, args);
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



function [code, dim, extra_code] = parseOtherFunc(tree, args)
    global SF_MF_FUNCTIONS_MAP;
    extra_code = {};
    dim = [1 1];
    if (args.isStateFlow || args.isMatlabFun) && args.data_map.isKey(tree.ID)
        %Array Access
        [code, ~, dim, extra_code] = arrayAccess_To_Lustre(tree, args);
        
    elseif (args.isStateFlow || args.isMatlabFun) && SF_MF_FUNCTIONS_MAP.isKey(tree.ID)
        %Stateflow Function and Matlab Function block
        [code, extra_code] = sf_mf_functionCall_To_Lustre(tree, args);
        
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
        if evalin('base', sprintf('exist(''%s'', ''var'')', tree.ID))
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
            if strcmp(args.expected_lusDT, 'int')
                code = nasa_toLustre.lustreAst.IntExpr(value);
            elseif strcmp(args.expected_lusDT, 'bool')
                code = nasa_toLustre.lustreAst.BoolExpr(value);
            else
                code = nasa_toLustre.lustreAst.RealExpr(value);
            end
        else 
            display_msg(...
                sprintf('Function "%s" is not handled in Block %s. The code will be abstracted.',...
                tree.ID, args.blk.Origin_path),...
                MsgType.WARNING, 'MExpToLusAST.fun_indexing_To_Lustre', '');
            %display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.fun_indexing_To_Lustre', '');
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






