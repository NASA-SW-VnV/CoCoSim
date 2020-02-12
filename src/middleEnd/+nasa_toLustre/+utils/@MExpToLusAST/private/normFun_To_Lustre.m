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
function [code, exp_dt, dim, extra_code] = normFun_To_Lustre(tree, args)

    
    dim = [1 1];
    [~, ~, x_dim, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    if isa(tree.parameters, 'struct')
        params = arrayfun(@(x) x, tree.parameters, 'UniformOutput', 0);
    else
        params = tree.parameters;
    end
    
    x_text = params{1}.text;
    p_text = '2';
    
    if length(params) > 1
        if strcmp(params{2}.type, 'constant')
            p_text = params{2}.text;
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Second argument of norm in expression "%s" must be a constant.',...
                tree.text);
            throw(ME);
        end
    end
    
    
    if length(x_dim) <= 2 && (x_dim(1) == 1 || x_dim(2) == 1)  % isvector
        switch p_text
            case 'Inf'
                % TODO : support inf arguments
                expr = sprintf("max(abs(%s))", x_text);
            case '-Inf'
                % TODO : support inf arguments
                expr = sprintf("min(abs(%s))", x_text);
            case '1'
                expr = sprintf("sum(abs(%s))", x_text);
            case '2'
                expr = sprintf("sqrt(sum((%s).^2))", x_text);
            otherwise
                expr = sprintf("sum(abs(%s).^%s))^(1/%s)", x_text, p_text, p_text);
        end
    else  % ismatrix
        switch p_text
            case 'Inf'
                % TODO : support inf arguments
                expr = sprintf("max(sum(abs((%s)')))", x_text);
            case "'fro'"
                expr = sprintf("sqrt(trace((%s)'*(%s)))", x_text, x_text);
            case '1'
                expr = sprintf("max(sum(abs(%s)))", x_text);
            case '2'
                % TODO : support this case
                ME = MException('COCOSIM:TREE2CODE', ...
                    'norm in expression "%s" is not supported.',...
                    tree.text);
                throw(ME);
            otherwise  % should never happen
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Unexpected case in norm expression "%s"',...
                    tree.text);
                throw(ME);
        end
    end
    
    new_tree = coco_nasa_utils.MatlabUtils.getExpTree(expr);
    
    [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
    
end