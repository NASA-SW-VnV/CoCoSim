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
function [first_arg, second_arg, m, n, y, perm, pre_exp, extra_code] = trapzUtil(tree, args)

%    
    
    perm = [];
    pre_exp = "";
    [x, ~, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    x = reshape(x, x_dim);
    if isa(tree.parameters, 'struct')
        params = arrayfun(@(x) x, tree.parameters, 'UniformOutput', 0);
    else
        params = tree.parameters;
    end
    if length(tree.parameters) >= 2
        [y, ~, y_dim, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
        y = reshape(y, y_dim);
        second_arg = params{2}.text;
    end
    if length(tree.parameters) >= 3
        [dimension, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(3), args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    end
    
    if length(tree.parameters) == 3 % cumtrapz(x, y, dim)
        if ~isa(dimension{1}, 'nasa_toLustre.lustreAst.RealExpr') && ...
                ~isa(dimension{1}, 'nasa_toLustre.lustreAst.IntExpr')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function cumtrapz in expression "%s" third argument must be a constant',...
                tree.text);
            throw(ME);
        end
        dimension = min(length(y_dim)+1, dimension{1}.value);
        perm_str = sprintf("[%d:%d, 1:%d]", dimension, max(length(y_dim), dimension), dimension-1);
        pre_exp = sprintf("%s = permute(%s, %s);", second_arg, second_arg, perm_str);
        perm = [dimension:max(length(y_dim), dimension), 1:dimension-1];
        y = permute(y, perm);
        [m, n] = size(y);
        first_arg = params{1}.text;
    elseif length(tree.parameters) == 2 && prod(y_dim) == 1 % cumtrapz(x, dim)
        if ~isa(y{1}, 'nasa_toLustre.lustreAst.RealExpr') && ...
                ~isa(y{1}, 'nasa_toLustre.lustreAst.IntExpr')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function cumtrapz in expression "%s" second argument must be a constant',...
                tree.text);
            throw(ME);
        end
        dimension = y{1}.value;
        y = x;
        y_dim = x_dim;
        second_arg = tree.parameters{1}.text;
        dimension = min(length(y_dim)+1, dimension);
        perm_str = sprintf("[%d:%d, 1:%d]", dimension, max(length(y_dim), dimension), dimension-1);
        pre_exp = sprintf("%s = permute(%s, %s);", second_arg, second_arg, perm_str);
        perm = [dimension:max(length(y_dim), dimension), 1:dimension-1];
        y = permute(y, perm);
        [m, n] = size(y);
        first_arg = sprintf('(1:%d)''', m);
    else % cumtrapz(y) or cumtrapz(x,y)
        if length(tree.parameters) < 2
            y = x;
            second_arg = tree.parameters.text;
            [y,nshifts] = shiftdim(y);
            [m, n] = size(y);
            first_arg = sprintf('(1:%d)''', m);
        else
            [y,nshifts] = shiftdim(y);
            [m, n] = size(y);
            first_arg = params{1}.text;
        end
        
        dimension = nshifts + 1;
    end
    
    
end