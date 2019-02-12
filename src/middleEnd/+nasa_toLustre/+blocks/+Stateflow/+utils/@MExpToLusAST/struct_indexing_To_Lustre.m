function [code, exp_dt] = struct_indexing_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    tree_ID = tree.ID;
    switch tree_ID
        case {'coder'}
            %ignore these Matlab class
            code = {};
            exp_dt = '';
            
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" is not supported in Block %s.',...
                tree.text, blk.Origin_path);
            throw(ME);
    end
    
end

