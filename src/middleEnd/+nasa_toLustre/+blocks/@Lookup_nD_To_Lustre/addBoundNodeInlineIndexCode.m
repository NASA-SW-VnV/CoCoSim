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
function [body, vars, boundingi] = ...
    addBoundNodeInlineIndexCode(index_node,Ast_dimJump,blkParams)

%
    % This function find inline index of bounding nodes
    indexDataType = 'int';
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    numBoundNodes = 2^NumberOfTableDimensions;
%     shapeNodeSign = ...
%         nasa_toLustre.blocks.Lookup_nD_To_Lustre.getShapeBoundingNodeSign(...
%         NumberOfTableDimensions);    
    body = cell(1,numBoundNodes);     
    vars = cell(1,numBoundNodes);            
    % defining boundingi{i}
    boundingi = cell(1,numBoundNodes);
    for i=1:numBoundNodes
        boundingi{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('bound_node_index_inline%d',i));
    end    

    for i=1:numBoundNodes
        %dimSign = shapeNodeSign(i,:);
        % declaring boundingi{i}
        boundingi{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('bound_node_index_inline%d',i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            boundingi{i},indexDataType);

        %value = '0';
        terms = cell(1,NumberOfTableDimensions);
        for j=1:NumberOfTableDimensions
            % dimSign(j): 0 is low, 1: high
            node2bin = strcat('000000', dec2bin(i-1));
            if strcmp(node2bin(end-j+1), '0') %dimSign(j) == -1
                curIndex =  index_node{j,1};
            else
                curIndex =  index_node{j,2};
            end
            % check logic here
            if strcmp(blkParams.InterpMethod,'Flat')  % doesn't use bound node 2
                curIndex =  index_node{j,1};
            end
            if j==1
                terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    curIndex,Ast_dimJump{j});
            else
                terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                    curIndex, ...
                    nasa_toLustre.lustreAst.IntExpr(1)),...
                    Ast_dimJump{j});
            end
        end
        if NumberOfTableDimensions == 1
            value = terms{1};
        else
            value = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.PLUS,terms);
        end
        body{i} = nasa_toLustre.lustreAst.LustreEq(boundingi{i},value);

    end
    
end