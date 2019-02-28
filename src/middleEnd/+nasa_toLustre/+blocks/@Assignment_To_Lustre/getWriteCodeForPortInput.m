function [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    %% function get code for noPortInput
    % initialization
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    indexDataType = 'int';
    
    if numOutDims>7
        display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
            HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'Assignment_To_Lustre', '');
    end
    U_index = {};
    addVars = {};
    addVarIndex = 0;
    for i=1:numel(inputs{2})
        U_index{i} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('%s_U_index_%d',...
            blk_name,i));
        addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(U_index{i},indexDataType);
    end
    % pass to Lustre ind
    codes = {};
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
            if strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                for j=1:numel(ind{i})
                    v_name = nasa_toLustre.lustreAst.VarIdExpr(...
                        sprintf('%s_ind_dim_%d_%d',...
                        blk_name,i,j));
                    addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(v_name, indexDataType);
                    
                    if j==1
                        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(v_name, ind{i}{1}) ;
                    else
                        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(v_name,...
                            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                            ind{i}{1}, ...
                            nasa_toLustre.lustreAst.IntExpr(j-1))) ;
                        %sprintf('%s_ind_dim_%d_%d = %s + %d;\n\t',...
                        %    blk_name,i,j, ind{i}{1}, (j-1)) ;
                    end
                end
            else   % 'Index vector (port)'
                for j=1:numel(ind{i})
                    v_name = nasa_toLustre.lustreAst.VarIdExpr(...
                        sprintf('%s_ind_dim_%d_%d',...
                        blk_name,i,j));
                    addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(v_name, indexDataType);
                    codes{end + 1} =  nasa_toLustre.lustreAst.LustreEq(v_name, ind{i}{j});
                    %sprintf('%s_ind_dim_%d_%d = %s;\n\t',...
                    %    blk_name,i,j, ind{i}{j}) ;
                end
            end
        end
    end
    % dimJump is needed to do sub2ind
    Y0_dimJump = ones(1,numel(in_matrix_dimension{1}.dims));
    for i=2:numel(in_matrix_dimension{1}.dims)
        for j=1:i-1
            Y0_dimJump(i) = Y0_dimJump(i)*in_matrix_dimension{1}.dims(j);
        end
    end
    U_dimJump = ones(1,numel(U_expanded_dims.dims));
    for i=2:numel(U_expanded_dims.dims)
        for j=1:i-1
            U_dimJump(i) = U_dimJump(i)*U_expanded_dims.dims(j);
        end
    end
    varId_Y_index = {};
    for i=1:numel(inputs{2})    % looping over U elements
        curSub = ones(1,numel(U_expanded_dims.dims));
        % ind2sub
        [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(U_expanded_dims.dims,i);   % 7 dims max
        curSub(1) = d1;
        curSub(2) = d2;
        curSub(3) = d3;
        curSub(4) = d4;
        curSub(5) = d5;
        curSub(6) = d6;
        curSub(7) = d7;
        for j=1:numel(in_matrix_dimension{1}.dims)
            varId_Y_index{i}{j} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('%s_str_Y_index_%d_%d',...
                blk_name,i,j));
            addVars{end + 1} = nasa_toLustre.lustreAst.LustreVar(varId_Y_index{i}{j}, indexDataType);
            codes{end + 1} = nasa_toLustre.lustreAst.LustreEq(varId_Y_index{i}{j}, ...
                nasa_toLustre.lustreAst.VarIdExpr(sprintf('%s_ind_dim_%d_%d',...
                blk_name,j,curSub(j))));
            %sprintf('%s = %s_ind_dim_%d_%d;\n\t',...
            %    str_Y_index{i}{j},blk_name,j,curSub(j)) ;
        end
        value = nasa_toLustre.lustreAst.IntExpr('0');
        value_terms = cell(1, numel(in_matrix_dimension{1}.dims));
        for j=1:numel(in_matrix_dimension{1}.dims)
            if j==1
                value_terms{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    varId_Y_index{i}{j}, nasa_toLustre.lustreAst.IntExpr(Y0_dimJump(j)));
                %value = sprintf('%s + %s*%d',value,str_Y_index{i}{j}, Y0_dimJump(j));
            else
                value_terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                    varId_Y_index{i}{j}, ...
                    nasa_toLustre.lustreAst.IntExpr(1)), ...
                    nasa_toLustre.lustreAst.IntExpr(Y0_dimJump(j)));
                %value = sprintf('%s + (%s-1)*%d',value,str_Y_index{i}{j}, Y0_dimJump(j));
            end
        end
        value = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS, value_terms);
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq( U_index{i}, value);
    end
    if numel(in_matrix_dimension{1}.dims) > 7
        
        display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
            HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'Assignment_To_Lustre', '');
    end
    for i=1:numel(outputs)
        conds = {};
        thens = {};
        for j=numel(inputs{2}):-1:1
            conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ,...
                U_index{j}, nasa_toLustre.lustreAst.IntExpr(i));
            thens{end + 1} = inputs{2}{j};
            %if j==numel(inputs{2})
            %code = sprintf('%s  if(%s = %d) then %s\n\t', code, U_index{j},i,inputs{2}{j});
            %else
            %   code = sprintf('%s  else if(%s = %d) then %s\n\t', code, U_index{j},i,inputs{2}{j});
            %end
        end
        %codes{end + 1} = sprintf('%s  else %s ;\n\t', code,inputs{1}{i});
        thens{end + 1} = inputs{1}{i};
        code = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens);
        codes{end + 1} = nasa_toLustre.lustreAst.LustreEq( outputs{i}, code);
    end
    obj.addVariable(addVars);
end
