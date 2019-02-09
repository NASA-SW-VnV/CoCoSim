
function [codes] = getWriteCodeForPortInput(obj,blk,numOutDims,inputs,outputs,ind,outputDimsArray,in_matrix_dimension)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
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
            U_index{i} = VarIdExpr(...
                sprintf('%s_U_index_%d',blk_name,i));
            addVars{end + 1} = LustreVar(U_index{i}, indexDataType);
        end

        % pass to Lustre ind
        for i=1:numel(ind)
            if ~MatlabUtils.contains(blk.IndexOptionArray{i}, '(port)')
                for j=1:numel(ind{i})
                    v_name =  VarIdExpr(...
                        sprintf('%s_ind_dim_%d_%d',...
                       blk_name,i,j));
                    addVars{end + 1} = LustreVar(v_name, indexDataType);
                    codes{end + 1} = LustreEq(v_name, IntExpr(ind{i}(j))) ;
                end
            else
                % port
                %portNum = indPortNumber(i);
                if strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                    for j=1:numel(ind{i})
                        v_name =  VarIdExpr(...
                            sprintf('%s_ind_dim_%d_%d',...
                           blk_name,i,j));
                        addVars{end + 1} = LustreVar(v_name, indexDataType);
                        if j==1
                            codes{end + 1} = LustreEq(v_name, ind{i}{1}) ;
                        else
                            codes{end + 1} = LustreEq(v_name, ...
                                BinaryExpr(BinaryExpr.PLUS, ...
                                ind{i}{1}, IntExpr(j-1)));
                        end
                    end                            
                else   % 'Index vector (port)'
                    for j=1:numel(ind{i})
                        v_name =  VarIdExpr(...
                            sprintf('%s_ind_dim_%d_%d',...
                           blk_name,i,j));
                        addVars{end + 1} = LustreVar(v_name, indexDataType);
                        codes{end + 1} = LustreEq(v_name, ind{i}{j}) ;
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
                ast_Y_index{i}{j} = VarIdExpr(...
                    sprintf('%s_str_Y_index_%d_%d',...
                   blk_name,i,j));
                addVars{end + 1} = LustreVar(...
                    ast_Y_index{i}{j}, indexDataType);
                codes{end + 1} = LustreEq(ast_Y_index{i}{j},...
                    VarIdExpr(...
                    sprintf('%s_ind_dim_%d_%d', blk_name,j,curSub(j)))) ;
            end

            % calculating sub2ind in Lustre
            value_args = cell(1, numel(outputDimsArray));
            for j=1:numel(outputDimsArray)
                if j==1
                    value_args{j} = BinaryExpr(BinaryExpr.MULTIPLY, ...
                        ast_Y_index{i}{j}, ...
                        IntExpr(U_dimJump(j)));
                    %value = sprintf('%s + %s*%d',value,ast_Y_index{i}{j}, U_dimJump(j));
                else
                    value_args{j} = BinaryExpr(BinaryExpr.MULTIPLY, ...
                        BinaryExpr(BinaryExpr.MINUS, ...
                                    ast_Y_index{i}{j}, ...
                                    IntExpr(1)), ...
                        IntExpr(U_dimJump(j)));
                    %value = sprintf('%s + (%s-1)*%d',value,ast_Y_index{i}{j}, U_dimJump(j));
                end
            end
            value = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, ...
                value_args);
            codes{end + 1} = LustreEq( U_index{i}, value);
        end
        if numel(in_matrix_dimension{1}.dims) > 7                    
            display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
                indexBlock.Origin_path), ...
                MsgType.ERROR, 'Selector_To_Lustre', '');
        end

        % writing outputs code
        for i=1:numel(outputs)
            n = numel(inputs{1});
            conds = cell(1, n -1);
            thens = cell(1, n);
            for j=n:-1:2
                conds{n - j + 1} = BinaryExpr(BinaryExpr.EQ, ...
                    U_index{i}, IntExpr(j));
                thens{n - j + 1} = inputs{1}{j};
            end
            thens{n} = inputs{1}{1};
            codes{end + 1} = LustreEq(outputs{i}, ...
                IteExpr.nestedIteExpr(conds, thens));
        end

        obj.addVariable(addVars);            
end
