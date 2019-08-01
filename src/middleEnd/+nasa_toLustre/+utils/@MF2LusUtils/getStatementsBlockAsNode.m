function [main_node] = getStatementsBlockAsNode(tree, args, type)
    %ABSTRACT_STATEMENTS_BLOCK generates a seperate node for a block of
    %statements such as content of FOR or WHILE ..
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    persistent counter;
    if isempty(counter)
        counter = 0;
    end
    main_node = {};
    body = {};
    outputs = {};
    inputs = {};
    
    statements = tree.statements;
    for i=1:length(statements)
        if isstruct(statements)
            s = statements(i);
        else
            s = statements{i};
        end
        lusCode = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(s, args);
        body = MatlabUtils.concat(body, lusCode);
        [outputs_i, inputs_i] = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getInOutputsFromAction(lusCode, ...
            false, args.data_map, s.text, true);
        outputs = [outputs, outputs_i];
        inputs = [inputs, inputs_i];
    end
    counter = counter + 1;
    node_name = sprintf('%s_%s_loop_%d', ...
        nasa_toLustre.utils.SLX2LusUtils.node_name_format(args.blk), type, ...
        counter);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('%s code is called inside Matlab Function block: %s\n The code is the following :\n%s',...
        type, args.blk.Origin_path, tree.text), true);
    main_node = nasa_toLustre.lustreAst.LustreNode();
    main_node.setName(node_name);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
end
