%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function [in_matrix_dimension, U_expanded_dims,inputs] = ...
        expand_U(~, parent,blk,inputs,numOutDims)
  
    
    in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
    U_expanded_dims = in_matrix_dimension{2};
    % if U input is a scalar and it is to be expanded, U_expanded_dims
    % needed to be calculated.
    indexPortNumber = 0;
    if numel(inputs{2}) == 1
        U_expanded_dims.numDs = numOutDims;
        U_expanded_dims.dims = ones(1,numOutDims);
        U_expanded_dims.width = 1;
        for i=1:numOutDims
            if strcmp(blk.IndexOptionArray{i}, 'Assign all')
                U_expanded_dims.dims(i) = in_matrix_dimension{1}.dims(i);
            elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                U_expanded_dims.dims(i) = ...
                    numel(nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk,blk.IndexParamArray{i}));
            elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                indexPortNumber = indexPortNumber + 1;
                portNumber = indexPortNumber + 2;
                U_expanded_dims.dims(i) = numel(inputs{portNumber});
            elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                U_expanded_dims.dims(i) = 1;
            elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                U_expanded_dims.dims(i) = 1;
            else
            end
            U_expanded_dims.width = U_expanded_dims.width*U_expanded_dims.dims(i);
        end
    end
    
    if numel(inputs{2}) == 1 && numel(inputs{2}) < U_expanded_dims.width
        inputs{2} = arrayfun(@(x) {inputs{2}{1}}, (1:U_expanded_dims.width));
        in_matrix_dimension{2} = U_expanded_dims;
    end
end
