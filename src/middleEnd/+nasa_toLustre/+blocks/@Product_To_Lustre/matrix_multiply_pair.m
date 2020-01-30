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
function [codes, product_out, addVars] = matrix_multiply_pair(m1_dim, m2_dim, ...
        input_m1, input_m2, output_m, zero, pair_number,...
        OutputDT, tmp_prefix, conv_format, operandsDT)
    
    
    % adding additional variables for inside matrices.  For
    % AxBxCxD, B and C are inside matrices and needs additional
    % variables

    initCode = zero;
    m=m1_dim.dims(1,1);
    if numel(m1_dim.dims) > 1
        n=m1_dim.dims(1,2);
    else
        n = 1;
    end
    if numel(m2_dim.dims) > 1
        l=m2_dim.dims(1,2);
    else
        l = 1;
    end
    addVars = {};
    if numel(output_m) == 0
        index = 0;
        addVars = cell(1, m*l);
        product_out = cell(1, m*l);
        for i=1:m
            for j=1:l
                index = index+1;
                product_out{index} = nasa_toLustre.lustreAst.VarIdExpr(...
                    sprintf('%s_matrix_mult_%d_%d',...
                    tmp_prefix, pair_number,index));
                addVars{index} = nasa_toLustre.lustreAst.LustreVar(...
                    product_out{index}, OutputDT);
            end
        end
    else
        product_out = output_m;
    end
    % doing matrix multiplication, A = BxC
    codes = cell(1, m*l);
    codeIndex = 0;
    for i=1:m      %i is row of result matrix
        for j=1:l      %j is column of result matrix
            codeIndex = codeIndex + 1;
            code = initCode;
            for k=1:n
                aIndex = sub2ind([m,n],i,k);
                bIndex = sub2ind([n,l],k,j);
                code = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                    code, ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ...
                    input_m1{1,aIndex}, input_m2{1,bIndex}, [], [], [], operandsDT),...
                    false);
                %sprintf('%s + (%s * %s)',code, input_m1{1,aIndex},input_m2{1,bIndex});
                %diag = sprintf('i %d, j %d, k %d, aIndex %d, bIndex %d',i,j,k,aIndex,bIndex);
            end
            productOutIndex = sub2ind([m,l],i,j);
            if ~isempty(conv_format) && ~isempty(output_m)
                code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, code);
            end
            codes{codeIndex} = nasa_toLustre.lustreAst.LustreEq(product_out{productOutIndex}, code) ;
        end

    end
end
