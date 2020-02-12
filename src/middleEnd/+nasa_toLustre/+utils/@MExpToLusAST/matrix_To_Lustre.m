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
function [code, dt, dim, extra_code] = matrix_To_Lustre(tree, args) 
    dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    extra_code = {};
    if isstruct(tree.rows)
        rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
    else
        rows = tree.rows;
    end
    
    nb_rows = numel(rows);
    nb_columns = numel(rows{1});
    if ischar(dt)
        code_dt = arrayfun(@(i) dt, ...
            (1:nb_rows*nb_columns), 'UniformOutput', false);
    elseif iscell(dt) && numel(dt) < nb_rows*nb_columns
        code_dt = arrayfun(@(i) dt{1}, ...
            (1:nb_rows*nb_columns), 'UniformOutput', false);
    else
        code_dt = dt;
    end
    if isrow(code_dt), code_dt = code_dt'; end
    code = {};
    code_dt = reshape(code_dt, nb_rows, nb_columns);
    if args.isLeft && nb_rows == 1
        %e.g., [x, y] = f(...)
        for j=1:nb_columns
            for i=1:nb_rows
                v = rows{i}(j);
                args.expected_lusDT = code_dt{i, j};
                [code_i, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    v, args);
                extra_code = coco_nasa_utils.MatlabUtils.concat(extra_code, extra_code_i);
                code = coco_nasa_utils.MatlabUtils.concat(code, code_i);
            end
        end
        dim = [1 length(code)];
    else
        code_rows = [];
        for i=1:nb_rows
            code_i = [];
            for j=1:nb_columns
                v = rows{i}(j);
                args.expected_lusDT = code_dt{i, j};
                [code_j, ~, code_dim, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    v, args);
                extra_code = coco_nasa_utils.MatlabUtils.concat(extra_code, extra_code_i);
                if isrow(code_j), code_j = code_j'; end
                code_j = reshape(code_j, code_dim);
                code_i = [code_i, code_j];
            end
            code_rows = [code_rows; code_i];
        end
        dim = size(code_rows);
        code = reshape(code_rows, numel(code_rows), 1);
    end
    
end
