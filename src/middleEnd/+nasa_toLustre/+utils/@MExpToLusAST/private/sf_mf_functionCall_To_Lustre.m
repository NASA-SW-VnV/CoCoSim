function code = sf_mf_functionCall_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    
    global SF_MF_FUNCTIONS_MAP ;
    
    if isa(tree.parameters, 'struct')
        parameters = arrayfun(@(x) x, tree.parameters, 'UniformOutput', false);
    else
        parameters = tree.parameters;
    end
    actionNodeAst = SF_MF_FUNCTIONS_MAP(tree.ID);
    node_inputs = actionNodeAst.getInputs();
    if isempty(parameters)
        [call, ~] = actionNodeAst.nodeCall();
        code = call;
    else
        params_dt =  cellfun(@(x) x.getDT(), node_inputs, 'UniformOutput', 0);
        params_ast = {};
        dt_idx = 1;
        for i=1:numel(parameters)
            [f_args, dt] = ...
                nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                parameters{i}, args);
            f_args = nasa_toLustre.utils.MExpToLusDT.convertDT(args.blkObj, f_args, dt, params_dt{dt_idx});
            dt_idx = dt_idx + length(f_args);
            params_ast = MatlabUtils.concat(params_ast, f_args);
        end
        if numel(node_inputs) == numel(params_ast)
            code = nasa_toLustre.lustreAst.NodeCallExpr(actionNodeAst.getName(), params_ast);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" expected %d parameters but got %d',...
                tree.ID, numel(node_inputs), numel(tree.parameters));
            throw(ME);
        end
    end
    
end
