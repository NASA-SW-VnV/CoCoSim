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
function [code, exp_dt, dim, extra_code] = circshiftFun_To_Lustre(tree, args)

%    
    [X, X_dt, X_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    args.expected_lusDT = 'int';
    [Y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2),args);
    extra_code = coco_nasa_utils.MatlabUtils.concat(extra_code, extra_code_i);
    X_reshp = reshape(X, X_dim);
    if isempty(Y) || (~isa(Y{1}, 'nasa_toLustre.lustreAst.RealExpr') ...
            && ~isa(Y{1}, 'nasa_toLustre.lustreAst.IntExpr')) ...
            || ((length(Y) == 2 && ~isa(Y{2}, 'nasa_toLustre.lustreAst.RealExpr')) ...
            && (length(Y) == 2 && ~isa(Y{2}, 'nasa_toLustre.lustreAst.IntExpr')))
         ME = MException('COCOSIM:TREE2CODE', ...
            'Second argument in function circshift in expression "%s" should be a constant.',...
            tree.text);
        throw(ME);
    end
    if numel(Y) == 1
        Y = Y{1}.getValue();
    elseif numel(Y) == 2
        Y = [Y{1}.getValue() Y{2}.getValue()];
    else
        % TODO support more than 2 dim
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function circshift in expression "%s" second argument is %d-dimension, more than 2 is not supported.',...
            tree.text, numel(Y));
        throw(ME);
    end
    
    if (length(tree.parameters) > 2)
        args.expected_lusDT = 'int';
        [d, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(3),args);
        extra_code = coco_nasa_utils.MatlabUtils.concat(extra_code, extra_code_i);
        code1 = circshift(X_reshp, Y, d{1}.value);
    else
        code1 = circshift(X_reshp, Y);
    end
    exp_dt = X_dt;
    if isrow(code1), code1 = code1'; end
    code = reshape(code1, [prod(X_dim) 1]);
    dim = X_dim;
end

