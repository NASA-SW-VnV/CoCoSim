%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>, Francois Conzelmann <francois.conzelmann@nasa.gov>
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
function [code, exp_dt, dim, extra_code] = allAnyFun_To_Lustre(tree, args, op)

%    
    code = {};
    
    [x, x_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if length(x_dim) == 1
        x_dim = [x_dim, 1];
    end
    n_dim = numel(x_dim);
    x_new = reshape(x, x_dim);
    
    if length(tree.parameters) == 1
        if x_dim(1) == 1
            param2_value = 2;
        else
            param2_value = 1;
        end
    else
        param2 = tree.parameters{2};
        if param2.type == 'constant'
            param2_value = str2double(param2.value);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" in expression "%s" second argument is not a constant is not supported.',...
                tree.ID, tree.text);
            throw(ME);
        end
    end
    if param2_value == 1
        for i=1:prod(x_dim(2:end))
            code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_new(:, i));
        end
        dim = [1 x_dim(2:end)];
    elseif param2_value == 2
        if n_dim > 2
            for j=1:prod(x_dim(3:end))
                for i=1:x_dim(1)
                    code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_new(i, :, j));
                end
            end
        else
            for i=1:x_dim(1)
                code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_new(i, :));
            end
        end
        dim = [x_dim(1) 1 x_dim(3:end)];
    elseif param2_value == 3
        if n_dim > 3
            for k=1:prod(x_dim(4:end))
                for j=1:x_dim(2)
                    for i=1:x_dim(1)
                        code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                            op, x_new(i, j, :, k));
                    end
                end
            end
        else
            for j=1:x_dim(2)
                for i=1:x_dim(1)
                    code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                        op, x_new(i, j, :));
                end
            end
        end
        dim = [x_dim(1:2), 1, x_dim(4:end)];
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function "%s" in expression "%s" is not supported. The second parameter should be less than or equal to 3.',...
            tree.ID, tree.text);
        throw(ME);
    end
    if strcmp(op, nasa_toLustre.lustreAst.BinaryExpr.AND) ...
            || strcmp(op, nasa_toLustre.lustreAst.BinaryExpr.OR)
        % called from allFun_To_Lustre or anyFun_To_Lustre
        exp_dt = 'bool';
    else
        % called from sumFun_To_Lustre
        if iscell(x_dt)
            exp_dt = x_dt{1};
        else
            exp_dt = x_dt;
        end
    end
end
