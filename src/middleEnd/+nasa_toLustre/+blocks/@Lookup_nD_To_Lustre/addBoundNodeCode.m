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
function [body, vars,coords_node,index_node] = ...
        addBoundNodeCode(blkParams,Breakpoints,input_coords,lus_backend)

%    %  This function finds the bounding polytop which is required to define
    %  the shape functions.  For each dimension, there will be 2
    %  breakpoints that surround the coordinate of the interpolation
    %  point in that dimension.  For 2 dimensions, if the table is a
    %  mesh, then the polytop is the rectangle containing the
    %  interpolation point.
    %  For the 'Flat' case, only lower index is needed.
    %  For the 'Above" case, coords_2 is not needed
    body = {};
    vars = {};
    indexDataType = 'int';
    BreakpointsForDimension = blkParams.BreakpointsForDimension;
    InterpMethod = blkParams.InterpMethod;
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    % defining nodes bounding element
    %(coords_node{NumberOfTableDimensions,2}: dim1_low, dim1_high,
    % dim2_low, dim2_high,... dimn_low, dimn_high)
    
    % finding nodes bounding element
    coords_node = cell(NumberOfTableDimensions,2);
    index_node = cell(NumberOfTableDimensions,2);
    
    for i=1:NumberOfTableDimensions
        
        % low node for dimension i
        index_node{i,1} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('index_dim_%d_1',i));
        index_node{i,2} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('index_dim_%d_2',i));
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            index_node{i,1},indexDataType);
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            index_node{i,2},indexDataType);
        
        coords_node{i,1} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('coords_dim_%d_1',i));
        % high node for dimension i
        coords_node{i,2} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('coords_dim_%d_2',i));
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            coords_node{i,1},'real');
        %TODO why keep lower node in Above and not the upper
        if ~strcmp(InterpMethod,'Above')
            vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
                coords_node{i,2},'real');
        end
        
        % looking for low node
        conds = {};
        thens = {};
        for j=numel(BreakpointsForDimension{i}):-1:1
            epsilon = [];
            if nasa_toLustre.blocks.PreLookup_To_Lustre.bpIsInputPort(blkParams)
                epsilon = ...
                    nasa_toLustre.blocks.Lookup_nD_To_Lustre.calculate_eps(...
                    BreakpointsForDimension{i}, j);
            end
            conds{end+1} =  ...
                nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                input_coords{i},Breakpoints{i}{j}, [], ...
                coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend), epsilon);
            if j==numel(BreakpointsForDimension{i})
                % for extrapolation, we want to use the last 2
                % nodes
                lower_idx = nasa_toLustre.lustreAst.IntExpr(j-1);
                higher_idx =nasa_toLustre.lustreAst.IntExpr((j));
                lower_coord = Breakpoints{i}{j-1};
                higher_coord = Breakpoints{i}{j};
            else
                lower_idx = nasa_toLustre.lustreAst.IntExpr(j);
                higher_idx = nasa_toLustre.lustreAst.IntExpr(j+1);
                lower_coord = Breakpoints{i}{j};
                higher_coord = Breakpoints{i}{j+1};
            end
            if ~strcmp(InterpMethod,'Above')
                thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(...
                    {lower_idx, lower_coord, higher_idx, higher_coord});
            else
                thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(...
                    {lower_idx, lower_coord, higher_idx});
            end
        end
        lower_idx = nasa_toLustre.lustreAst.IntExpr(1);
        higher_idx = nasa_toLustre.lustreAst.IntExpr(2);
        lower_coord = Breakpoints{i}{1};
        higher_coord = Breakpoints{i}{2};
        if ~strcmp(InterpMethod,'Above')
            thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(...
                {lower_idx, lower_coord, higher_idx, higher_coord});
            lhs = nasa_toLustre.lustreAst.TupleExpr(...
                {index_node{i,1}, coords_node{i,1}, index_node{i,2}, coords_node{i,2}});
        else
            thens{end+1} = nasa_toLustre.lustreAst.TupleExpr(...
                {lower_idx, lower_coord, higher_idx});
            lhs = nasa_toLustre.lustreAst.TupleExpr(...
                {index_node{i,1}, coords_node{i,1}, index_node{i,2}});
        end
        rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
            conds, thens);
        
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(lhs, rhs);
        
    end
end

