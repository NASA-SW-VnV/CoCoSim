function [code, exp_dt] = convFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    % Do not forget to update exp_dt in each switch case if needed
    tree_ID = tree.ID;
    
    switch tree_ID
        case {'ceil', 'floor', 'round'}
            expected_param_dt = 'real';
            if ismember(tree_ID, {'ceil', 'floor', 'round'})
                fun_name = strcat('_', tree_ID);
                lib_name = strcat('LustDTLib_', fun_name);
            elseif isequal(tree_ID, 'fabs')
                fun_name = tree_ID;
                lib_name = strcat('LustMathLib_', fun_name);
            end
            BlkObj.addExternal_libraries(lib_name);
            
            [param, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, expected_param_dt, ...
                isSimulink, isStateFlow, isMatlabFun);
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = 'real';
            
        case {'int8', 'int16', 'int32', ...
                'uint8', 'uint16', 'uint32', ...
                'double', 'single', 'boolean'}
            
            param = tree.parameters(1);
            if isequal(param.type, 'constant')
                % cast of constant
                v = eval(tree.value);
                exp_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(tree_ID);
                code = cell(numel(v), 1);
                for i=1:numel(v)
                    code{i} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(v(i), exp_dt, tree_ID);
                end
            else
                % cast of expression/variable
                [param, param_dt] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                    parent, blk, data_map, inputs, '', isSimulink, isStateFlow, isMatlabFun);
                [external_lib, conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(param_dt, tree_ID);
                if ~isempty(conv_format)
                    BlkObj.addExternal_libraries(external_lib);
                    code = arrayfun(@(i) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, param{i}), ...
                        (1:numel(param)), 'UniformOutput', false);
                    exp_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(tree_ID);
                else
                    % no casting needed
                    code = param;
                    exp_dt = param_dt;
                end
            end
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, blk.Origin_path);
            throw(ME);
    end
end

