function [code, dt] = ID_To_Lustre(~, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    import nasa_toLustre.blocks.Stateflow.utils.*
    id = tree.name;
    dt = MExpToLusDT.ID_DT(tree, data_map, inputs, isSimulink, isStateFlow);
    if strcmp(id, 'true') || strcmp(id, 'false')
        code{1} = BooleanExpr(id);
        
    elseif isSimulink && strcmp(id, 'u')
        %the case of u with no index in IF/Fcn/SwitchCase blocks
        code{1} = inputs{1}{1};
        
    elseif isSimulink && ~isempty(regexp(id, 'u\d+', 'match'))
        %the case of u1, u2 in IF/Fcn/SwitchCase blocks
        input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
        code{1} = inputs{str2double(input_idx)}{1};
        
    elseif isKey(data_map, id)
        d = data_map(id);
        if isStateFlow
            names = SF_To_LustreNode.getDataName(d);
            code = cell(numel(names), 1);
            for i=1:numel(names)
                code{i} = VarIdExpr(names{i});
            end
        else
            code{1} = VarIdExpr(id);
        end
    else
        try
            %check for variables in workspace
            [value, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, id);
            if status
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s"', ...
                    id, blk.Origin_path);
                throw(ME);
            end
            dt = expected_dt;
            code = cell(numel(value), 1);
            for i=1:numel(value)
                if strcmp(expected_dt, 'bool')
                    code{i} = BooleanExpr(value(i));
                elseif strcmp(expected_dt, 'int')
                    code{i} = IntExpr(value(i));
                else
                    code{i} = RealExpr(value(i));
                    dt = 'real';
                end
            end
        catch me
            %code = VarIdExpr(var_name);
            ME = MException('COCOSIM:TREE2CODE', ...
                'Not found Variable "%s" in block "%s"', ...
                id, blk.Origin_path);
            throw(ME);
        end
    end
    
end