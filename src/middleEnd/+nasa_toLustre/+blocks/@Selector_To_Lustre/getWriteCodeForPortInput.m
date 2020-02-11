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
function [codes] = getWriteCodeForPortInput(obj,blk,numOutDims,inputs,outputs,ind,outputDimsArray,in_matrix_dimension)

%    
    
    if numOutDims>7
        display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
            indexBlock.Origin_path), ...
            MsgType.ERROR, 'Selector_To_Lustre', '');
    end
    codes = {};
    indexDataType = 'int';
    U_index = cell(1, numel(outputs));
    addVars = {};
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    for i=1:numel(outputs)
        U_index{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('%s_U_index_%d',blk_name,i));
        addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(U_index{i}, indexDataType);
    end
    
    % pass to Lustre ind
    for i=1:numel(ind)
        if ~MatlabUtils.contains(blk.IndexOptionArray{i}, '(port)')
            for j=1:numel(ind{i})
                v_name =  nasa_toLustre.lustreAst.VarIdExpr(...
                    sprintf('%s_ind_dim_%d_%d',...
                    blk_name,i,j));
                addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(v_name, indexDataType);
                codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(v_name, nasa_toLustre.lustreAst.IntExpr(ind{i}(j))) ;
            end
        else
            % port
            %portNum = indPortNumber(i);
            if strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                for j=1:numel(ind{i})
                    v_name =  nasa_toLustre.lustreAst.VarIdExpr(...
                        sprintf('%s_ind_dim_%d_%d',...
                        blk_name,i,j));
                    addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(v_name, indexDataType);
                    if j==1
                        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(v_name, ind{i}{1}) ;
                    else
                        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(v_name, ...
                            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                            ind{i}{1}, nasa_toLustre.lustreAst.IntExpr(j-1)));
                    end
                end
            else   % 'Index vector (port)'
                for j=1:numel(ind{i})
                    v_name =  nasa_toLustre.lustreAst.VarIdExpr(...
                        sprintf('%s_ind_dim_%d_%d',...
                        blk_name,i,j));
                    addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(v_name, indexDataType);
                    codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(v_name, ind{i}{j}) ;
                end
            end
        end
    end
    %calculating U_index{i}
    % 1D
    
    % See comments
    % at the top of Assignment_To_Lustre.m for code example of
    % getting inline index from subscripts of a multidimensional
    % array.
    
    Y_dimJump = ones(1,numel(outputDimsArray));
    for i=2:numel(outputDimsArray)
        for j=1:i-1
            Y_dimJump(i) = Y_dimJump(i)*outputDimsArray(j);
        end
    end
    U_dimJump = ones(1,numel(in_matrix_dimension{1}.dims));
    for i=2:numel(in_matrix_dimension{1}.dims)
        for j=1:i-1
            U_dimJump(i) = U_dimJump(i)*in_matrix_dimension{1}.dims(j);
        end
    end
    ast_Y_index = cell(1, numel(outputs));
    for i=1:numel(outputs)  % looping over Y elements
        curSub = ones(1,numel(outputDimsArray));
        % ind2sub
        [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(outputDimsArray,i);   % 7 dims max
        curSub(1) = d1;
        curSub(2) = d2;
        curSub(3) = d3;
        curSub(4) = d4;
        curSub(5) = d5;
        curSub(6) = d6;
        curSub(7) = d7;
        
        for j=1:numel(outputDimsArray)
            ast_Y_index{i}{j} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('%s_str_Y_index_%d_%d',...
                blk_name,i,j));
            addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
                ast_Y_index{i}{j}, indexDataType);
            codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(ast_Y_index{i}{j},...
                nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('%s_ind_dim_%d_%d', blk_name,j,curSub(j)))) ;
        end
        
        % calculating sub2ind in Lustre
        value_args = cell(1, numel(outputDimsArray));
        for j=1:numel(outputDimsArray)
            if j==1
                value_args{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ...
                    ast_Y_index{i}{j}, ...
                    nasa_toLustre.lustreAst.IntExpr(U_dimJump(j)));
                %value = sprintf('%s + %s*%d',value,ast_Y_index{i}{j}, U_dimJump(j));
            else
                value_args{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
                    ast_Y_index{i}{j}, ...
                    nasa_toLustre.lustreAst.IntExpr(1)), ...
                    nasa_toLustre.lustreAst.IntExpr(U_dimJump(j)));
                %value = sprintf('%s + (%s-1)*%d',value,ast_Y_index{i}{j}, U_dimJump(j));
            end
        end
        value = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            value_args);
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq( U_index{i}, value);
    end
    if numel(in_matrix_dimension{1}.dims) > 7
        display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
            indexBlock.Origin_path), ...
            MsgType.ERROR, 'Selector_To_Lustre', '');
    end
    
    % get Read table node
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lusOutDT = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
    readTableNode = nasa_toLustre.blocks.Selector_To_Lustre.get_read_table_node(blk_name, inputs{1}, lusOutDT);
    obj.addExtenal_node(readTableNode);
    
    readTableNodeName = readTableNode.getName();
    readTableInputs = cell(1, 1+numel(inputs{1}));
    readTableInputs(2:end) = inputs{1};
    % writing outputs code
    for i=1:numel(outputs)
        
        
        % Method 1: Go over inputs for each output
        %         n = numel(inputs{1});
        %         conds = cell(1, n -1);
        %         thens = cell(1, n);
        %         for j=n:-1:2
        %             conds{n - j + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
        %                 U_index{i}, nasa_toLustre.lustreAst.IntExpr(j));
        %             thens{n - j + 1} = inputs{1}{j};
        %         end
        %         thens{n} = inputs{1}{1};
        %         codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
        %             nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
        
        %Method 2: use a node to read table element to reduce repetitions
        readTableInputs{1} = U_index{i};
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(readTableNodeName, readTableInputs));
        
    end
    
    obj.addVariable(addVars);
end
