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
function [codes, AdditionalVars] = matrix_multiply(obj, exp, blk, inputs, outputs, zero, LusOutputDataTypeStr, conv_format, operandsDT )

    
    
    % check that the number of columns of 1st input matrix is equalled
    % to the number of rows of the 2nd matrix
    % matrix C(mxl) = A(mxn)*B(nxl)
    in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
    % the index of the current matrix pair
    pair_number = 0;
    codes = {};
    %AdditionalVars = {};
    productOutputs = {};
    tmp_prefix =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    [new_inputs, invertCodes, AdditionalVars] = nasa_toLustre.blocks.Product_To_Lustre.invertInputs(obj, exp, inputs, blk, LusOutputDataTypeStr);
    codes = [codes, invertCodes];
    for i=1:numel(in_matrix_dimension)-1
        pair_number = pair_number + 1;
        output_m = {};
        m2_dimension = in_matrix_dimension{i+1};
        if i==1
            m1_inputs = new_inputs{1};
            m1_dimension = in_matrix_dimension{i};
        else
            m1_inputs = productOutputs;
            m1_dim.dims(1,1) = in_matrix_dimension{1}.dims(1,1);
            m1_dim.dims(1,2) = in_matrix_dimension{i}.dims(1,2);
            m1_dimension = m1_dim;
        end
        if i==numel(in_matrix_dimension)-1
            output_m = outputs;
        end

        [code, productOutputs, addVar] = nasa_toLustre.blocks.Product_To_Lustre.matrix_multiply_pair(m1_dimension, ...
            m2_dimension, m1_inputs,...
            new_inputs{i+1}, output_m, zero, pair_number,...
            LusOutputDataTypeStr, tmp_prefix, conv_format, operandsDT);
        codes = [codes, code];
        %productOutputs = [productOutputs, tmp_outputs];
        AdditionalVars = [AdditionalVars, addVar];
    end
end
