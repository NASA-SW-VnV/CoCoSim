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
function [code, exp_dt, dim, extra_code] = binaryExpression_To_Lustre(tree, args)

    
    
    
    tree_type = tree.type;
    dim = [];
    extra_code = {};
    % get Operands DataType
    exp_dt = nasa_toLustre.utils.MExpToLusDT.binaryExpression_DT(tree, args);
    if ismember(tree_type, {'relopGL', 'relopEQ_NE'})
        left_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.leftExp, args);
        right_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.rightExp, args);
        operands_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(left_dt, right_dt);
    else
        operands_dt = exp_dt;
    end
    
    % GEt Left Right operand
    args.expected_lusDT = operands_dt;
    [left, ~, left_dim, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.leftExp, args);
    [right, ~, right_dim, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.rightExp, args);
    extra_code = coco_nasa_utils.MatlabUtils.concat(left_extra_code, right_extra_code);

    % Get Operator
    if strcmp(tree_type, 'plus_minus') % '+' '-'
        dim = left_dim;
        op = tree.operator;
    elseif strcmp(tree_type, 'mtimes') % '*'
        [code, dim] = nasa_toLustre.utils.MF2LusUtils.mtimesFun_To_Lustre(left, left_dim, right, right_dim, operands_dt);
        return;
    elseif strcmp(tree_type, 'times') % '.*'
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
            %TODO support more than 3 dimensions
        end
        op = nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY;
    elseif strcmp(tree_type, 'mrdivide')... % '/' './'
            || strcmp(tree_type, 'rdivide')
        if isempty(left_dim) ||  prod(left_dim) == 1
            dim = right_dim;
        elseif isempty(right_dim) ||  prod(right_dim) == 1
            dim = left_dim;
        elseif length(left_dim) <= 2 && length(right_dim) <= 2
            if strcmp(tree_type, 'mrdivide')
                dim = [left_dim(1), right_dim(1)];
            else
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Matrix division in Expression "%s" is not supported.',...
                    tree.text);
                throw(ME);
            end
        else
            %TODO support more than 3 dimensions
            dim = left_dim;
        end
        if strcmp(operands_dt, 'int')
            [code, exp_dt, extra_code] = getIntDivision(tree, args);
            return;
        else
            op = nasa_toLustre.lustreAst.BinaryExpr.DIVIDE;
        end
    elseif strcmp(tree_type, 'relopGL') % '<' '>' '<=' '>='
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        op = tree.operator;
    elseif strcmp(tree_type, 'relopEQ_NE') % '==' '~='
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        if strcmp(tree.operator, '==')
            op = nasa_toLustre.lustreAst.BinaryExpr.EQ;
        else
            op = nasa_toLustre.lustreAst.BinaryExpr.NEQ;
        end
    elseif ismember(tree_type, {'relopAND', 'relopelAND'}) % '&&' '&'
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        %TODO relopelAND is bitwise AND
        op = nasa_toLustre.lustreAst.BinaryExpr.AND;
    elseif ismember(tree_type, {'relopOR', 'relopelOR'}) % '||' '|'
        if isempty(left_dim) || (length(left_dim) >= 1 && prod(left_dim) == 1)
            dim = right_dim;
        else
            dim = left_dim;
        end
        %TODO relopelOR is bitwise OR
        op = nasa_toLustre.lustreAst.BinaryExpr.OR;
        
    elseif ismember(tree_type, {'mpower', 'power'}) % '^' '.^'
        [code, exp_dt, dim, extra_code] = getPowerCode(tree, args);
        return;
    end
    
    % inline operands
    [left, right] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(left, right, tree);
    
    % create code
    code = arrayfun(@(i) nasa_toLustre.lustreAst.BinaryExpr(op, left{i}, right{i}, false, [], [], operands_dt), ...
        (1:numel(left)), 'UniformOutput', false);
end

function [code, exp_dt, dim, extra_code] = getPowerCode(tree, args)
    
    exp_dt = 'real';
    tree_type = tree.type;
    args.blkObj.addExternal_libraries('LustMathLib_lustrec_math');
    args.expected_lusDT = 'real';
    [left, ~, left_dim, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.leftExp, args);
    [right, ~, right_dim, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.rightExp, args);
    extra_code = coco_nasa_utils.MatlabUtils.concat(left_extra_code, right_extra_code);
    if numel(left) > 1 && strcmp(tree_type, 'mpower')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" has a power of matrix is not supported.',...
            tree.text);
        throw(ME);
    end
    if numel(right) == 1
        dim = left_dim;
        right = arrayfun(@(x) right{1}, (1:numel(left)), 'UniformOutput', false);
    else
        dim = right_dim;
    end
    code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr('pow', {left{i},right{i}}), ...
        (1:numel(left)), 'UniformOutput', false);
end

function [code, exp_dt, extra_code] = getIntDivision(tree, args)
    
    exp_dt = 'int';
    tree_type = tree.type;
    args.blkObj.addExternal_libraries('LustMathLib_int_div_Ceiling');
    args.expected_lusDT = 'int';
    [left, ~, left_dim, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.leftExp, args);
    [right, ~, right_dim, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.rightExp, args);
    extra_code = coco_nasa_utils.MatlabUtils.concat(left_extra_code, right_extra_code);
    left_is_scalar = isempty(left_dim) || prod(left_dim) == 1;
    right_is_scalar = isempty(right_dim) || prod(right_dim) == 1;
    
    if ~(left_is_scalar && right_is_scalar) && strcmp(tree_type, 'rdivide')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Matrix division in Expression "%s" is not supported.',...
            tree.text);
        throw(ME);
    end
    if length(right) == 1
        right = arrayfun(@(x) right{1}, (1:length(left)), 'UniformOutput', false);
    end
    code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr('int_div_Ceiling', {left{i},right{i}}), ...
        (1:numel(left)), 'UniformOutput', false);
end
