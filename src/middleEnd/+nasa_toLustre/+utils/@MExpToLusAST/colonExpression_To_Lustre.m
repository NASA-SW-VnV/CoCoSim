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
function [code, exp_dt, dim, extra_code] = colonExpression_To_Lustre(tree, args)

%    
    
    extra_code = {};
    if count(tree.text, ':') == 2
        if strcmp(tree.leftExp.leftExp.type, 'constant') && strcmp(tree.leftExp.rightExp.type, 'constant') && strcmp(tree.rightExp.type, 'constant')
            [left, left_dt, ~, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.leftExp.leftExp, args);
            [middle, middle_dt, ~, middle_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.leftExp.rightExp, args);
            [right, right_dt, ~, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.rightExp, args);
            extra_code = MatlabUtils.concat(left_extra_code, middle_extra_code, right_extra_code);

            upper_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(left_dt, right_dt);
            exp_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(upper_dt, middle_dt);
            left_value = left{1}.value;
            middle_value = middle{1}.value;
            right_value = right{1}.value;
            if strcmp(exp_dt, 'int')
                code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(x), (left_value:middle_value:right_value), 'UniformOutput', 0);
            else
                code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), (left_value:middle_value:right_value), 'UniformOutput', 0);
            end
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" only support constant input',...
                tree.text);
            throw(ME);
        end
        
    elseif count(tree.text, ':') == 1
        if ~isfield(tree, 'leftExp') && ~isfield(tree, 'rightExp')
            t = MatlabUtils.getExpTree('u(1:end)');
            tree = t.parameters(1);
        end
        c = symvar(tree.text);
        if isempty(c) || (length(c) == 1 && strcmp(c{1}, 'end'))
            try
                [code, exp_dt, dim] = nasa_toLustre.utils.MF2LusUtils.numFun_To_Lustre(...
                    tree, args);
            catch
                [left, left_dt, ~, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    tree.leftExp, args);
                [right, right_dt, ~, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    tree.rightExp, args);
                extra_code = MatlabUtils.concat(left_extra_code, right_extra_code);

                exp_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(left_dt, right_dt);
                if isa(left{1}, 'nasa_toLustre.lustreAst.IntExpr') || ...
                        isa(left{1}, 'nasa_toLustre.lustreAst.RealExpr')
                    left_value = left{1}.value;
                else
                    try
                        left_value = eval(left{1}.print(LusBackendType.LUSTREC));
                    catch
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" only support constant input',...
                            tree.text);
                        throw(ME);
                    end
                end
                if isa(right{1}, 'nasa_toLustre.lustreAst.IntExpr') || ...
                        isa(right{1}, 'nasa_toLustre.lustreAst.RealExpr')
                    right_value = right{1}.value;
                else
                    try
                        right_value = eval(right{1}.print(LusBackendType.LUSTREC));
                    catch
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" only support constant input',...
                            tree.text);
                        throw(ME);
                    end
                end
                if strcmp(exp_dt, 'int')
                    code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(x), (left_value:right_value), 'UniformOutput', 0);
                else
                    code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), (left_value:right_value), 'UniformOutput', 0);
                end
            end
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Using variable "%s" in expression "%s" is not supported.',...
                c{1}, tree.text);
            throw(ME);
        end
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" is not supported.',...
            tree.text);
        throw(ME);
    end
    dim = [1 numel(code)];
end

