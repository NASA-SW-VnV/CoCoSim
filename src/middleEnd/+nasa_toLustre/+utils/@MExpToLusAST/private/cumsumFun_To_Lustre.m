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
function [code, exp_dt, dim, extra_code] = cumsumFun_To_Lustre(tree, args)

%    
    reverse = false;
    dimension = 1;
    code = {};
    extra_code = {};
    op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    [x, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if isrow(x), x = x'; end

    if length(dim) > 2 % TODO support multi-dimension input
        msg = sprintf('Function cumsum in expression "%s" first argument is %d-dimension, more than 2 is not supported.',...
            tree.text, numel(x_dim));
        display_msg(msg, MsgType.ERROR, 'cumsumFun_To_Lustre', '');
        ME = MException('COCOSIM:TREE2CODE', msg);
        throw(ME);
    end
    
    if dim(1) == 1
        dimension = 2;
    end
    
    if length(tree.parameters) > 1
        if strcmp(tree.parameters{2}.type, 'String')
            reverse = strcmp(tree.parameters{2}.value, '''reverse''');
        else
            args.expected_lusDT = 'int';
            [y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
            extra_code = coco_nasa_utils.MatlabUtils.concat(extra_code, extra_code_i);
            dimension = y{1}.value;
        end
    end
    
    if length(tree.parameters) > 2
        reverse = strcmp(tree.parameters{3}.value, '''reverse''');
    end
    
    x_reshape = reshape(x, dim);
    
    if reverse
        if dimension == 1
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(i:end, j));
                end
            end
        else
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(i, j:end));
                end
            end
        end
    else
        if dimension == 1
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(1:i, j));
                end
            end
        else
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(i, 1:j));
                end
            end
        end
    end
    
    code = reshape(code, [prod(dim) 1]);
    
end


