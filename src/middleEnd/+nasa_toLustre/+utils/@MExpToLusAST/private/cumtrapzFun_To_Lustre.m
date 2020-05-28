%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
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
function [code, exp_dt, dim, extra_code] = cumtrapzFun_To_Lustre(tree, args)

%    
    
    [first_arg, second_arg, m, n, y, perm, pre_exp, extra_code] = ...
        nasa_toLustre.utils.MF2LusUtils.trapzUtil(tree, args);
    
    siz = size(y);
    
    if m >= 2
        left_exp = sprintf("[zeros(1, %d); ", n);
        dt_exp = sprintf("repmat(diff(%s,1,1)/2,1,%d)", first_arg, n);
        right_exp = sprintf("cumsum(%s .* (%s(1:%d,1:%d) + %s(2:%d,1:%d)), 1)];", ...
            dt_exp, second_arg, m-1, size(y,2), second_arg, m, size(y,2));
        expr = strcat(left_exp, right_exp);
    else
        expr = "[";
        for i=1:siz(2)
            expr = strcat(expr, "0 ");
        end
        expr = strcat(expr, "]");
    end
    
    % second_arg have a new size with the permutation. So we have to modify
    % the data map before we call `expression_To_Lustre` and restore it
    % after that
    
    data_map = args.data_map;
    saved_var = data_map(second_arg);
    modified_var = data_map(second_arg);
    new_size = replace(replace(replace(mat2str(size(y)), ' ', '  '), '[', ''), ']', '');
    modified_var.ArraySize = new_size;
    modified_var.CompiledSize = new_size;
    args.data_map(second_arg) = modified_var;
    
    new_tree = coco_nasa_utils.MatlabUtils.getExpTree(expr);
    code = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
    
    % restore data map state
    args.data_map(second_arg) = saved_var;
    
    
    code = reshape(code,siz);
    if ~isempty(perm) && numel(code) > 1, code = ipermute(code,perm); end
    dim = siz;
    code = reshape(code, [prod(dim), 1]);
    exp_dt = 'real';
    
    if ~strcmp(pre_exp, "")
        pre_tree = coco_nasa_utils.MatlabUtils.getExpTree(pre_exp);
        pre_code = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(pre_tree, args);
        extra_code = coco_nasa_utils.MatlabUtils.concat(extra_code, pre_code);
    end
    
    
end