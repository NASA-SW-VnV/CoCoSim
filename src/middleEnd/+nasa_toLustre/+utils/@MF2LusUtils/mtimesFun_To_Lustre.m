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
function [code, dim] = mtimesFun_To_Lustre(x, x_dim, y, y_dim, operandsDT)

%    
    
    
    
    code={};
    multi = nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY;
    plus = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    
    if prod(x_dim) == 1
        dim = y_dim;
        code = arrayfun(@(z) nasa_toLustre.lustreAst.BinaryExpr(multi, ...
            x, y(z), false, [], [], operandsDT), 1:numel(y), 'UniformOutput', 0);
    elseif prod(y_dim) == 1
        dim = x_dim;
        code = arrayfun(@(z) nasa_toLustre.lustreAst.BinaryExpr(multi, ...
            x(z), y, false, [], [], operandsDT), 1:numel(x), 'UniformOutput', 0);
    elseif length(x_dim) <= 2 && length(y_dim) <= 2
        
        x_reshape = reshape(x, x_dim);
        y_reshape = reshape(y, y_dim);
        
        dim = [x_dim(1), y_dim(2)];
        code_matrix = cell(x_dim(1), y_dim(2));
        for i=1:x_dim(1)
            for j=1:y_dim(2)
                exp = {};
                for k=1:x_dim(2)
                    exp{end+1} = nasa_toLustre.lustreAst.BinaryExpr(multi, ...
                        x_reshape(i, k), ...
                        y_reshape(k, j),...
                        false, [], [], operandsDT);
                end
                code_matrix(i,j) = {nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(plus, exp)};
            end
        end
        code = reshape(code_matrix, [1, numel(code_matrix)]);
    else  % should never happen as mtimes only works for matrix and scalar 
        ME = MException('COCOSIM:TREE2CODE', ...
            'Unexpected case in mtimes expression "%s"',...
            tree.text);
        throw(ME);
    end
end

