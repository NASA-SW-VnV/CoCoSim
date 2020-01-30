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
function [body, vars,L_dimjump] = addDimJumpCode(blkParams)

%
    %  This function defines dimJump.  table breakpoints and values are inline in Lustre, the
    %  interpolation formulation uses index for each dimension.  We
    %  need to get the inline data from the dimension subscript.
    %  Function addDimJumpCode calculate the index jump in the inline when we
    %  change dimension subscript.  For example dimJump(2) = 3 means
    %  to increase subscript dimension 2 by 1, we have to jump 3
    %  spaces in the inline storage.
    
    indexDataType = 'int';
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    body = cell(1,NumberOfTableDimensions);
    vars = cell(1,NumberOfTableDimensions);            
    dimJump = ones(1,NumberOfTableDimensions);
    L_dimjump = cell(1,NumberOfTableDimensions);
    L_dimjump{1} =  nasa_toLustre.lustreAst.VarIdExpr(...
        sprintf('dimJump_%d',1));
%     Ast_dimJump = cell(1,NumberOfTableDimensions);
%     Ast_dimJump{1} = nasa_toLustre.lustreAst.IntExpr(1);
    vars{1} = nasa_toLustre.lustreAst.LustreVar(...
        L_dimjump{1},indexDataType);
    body{1} = nasa_toLustre.lustreAst.LustreEq(...
        L_dimjump{1},nasa_toLustre.lustreAst.IntExpr(dimJump(1)));
    for i=2:NumberOfTableDimensions
        L_dimjump{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('dimJump_%d',i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            L_dimjump{i},indexDataType);
        for j=1:i-1
            if nasa_toLustre.utils.LookupType.isInterpolation_nD(blkParams.lookupTableType)
                tableSize = blkParams.TableDim;                
                dataPointInDim = tableSize(j);
            else    
                dataPointInDim = numel(blkParams.BreakpointsForDimension{j});
            end
            dimJump(i) = dimJump(i)*dataPointInDim;
        end
        body{i} = nasa_toLustre.lustreAst.LustreEq(...
            L_dimjump{i},nasa_toLustre.lustreAst.IntExpr(dimJump(i)));
%         Ast_dimJump{i} = nasa_toLustre.lustreAst.IntExpr(dimJump(i));
    end
end

