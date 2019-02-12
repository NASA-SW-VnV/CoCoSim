function [code, exp_dt] = constant_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    v = tree.value;
    exp_dt = expected_dt;
    if strcmp(expected_dt, 'real')
        code{1} = RealExpr(str2double(v));
    elseif strcmp(expected_dt, 'bool')
        code{1} = BooleanExpr(str2double(v));
    elseif strcmp(expected_dt, 'int')
        %tree might be 1 or 3e5
        code{1} = IntExpr(str2double(v));
    else
        %isempty(expected_dt)
        if isequal(tree.dataType, 'Integer')
            code{1} = IntExpr(str2double(v));
            exp_dt = 'int';
        elseif isequal(tree.dataType, 'Float')
            code{1} = RealExpr(str2double(v));
            exp_dt = 'real';
        else
            % String | function_handle
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" of type "%s" is not handled in Block %s',...
                tree.text, tree_type, blk.Origin_path);
            throw(ME);
        end
    end
end