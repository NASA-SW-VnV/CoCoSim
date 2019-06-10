function [main_node, iterator_node] = forIteratorNode(main_node, variables,...
        node_inputs, node_outputs, contract, ss_ir)
    %% ForIterator block
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %
    %
    % this node will be called many times using many
    % instances in the same time step. We need to not have
    % arrow in the node as each instance of the node has
    % its own memory, therefor different is_init values.

    %changePre2Var
    [main_node, memoryIds] = main_node.changePre2Var();

    %getForIteratorMemoryVars
    [new_variables, additionalOutputs, ...
        additionalInputs, inputsMemory] =...
        nasa_toLustre.frontEnd.SS_To_LustreNode.getForIteratorMemoryVars(variables, ...
        node_inputs, memoryIds);

    %changeArrowExp
    [~, ForBlk] = nasa_toLustre.blocks.SubSystem_To_Lustre.hasForIterator(ss_ir);
    ShowIterationPort = strcmp(ForBlk.ShowIterationPort, 'on');
    if ShowIterationPort
        iteration_dt = ForBlk.IterationVariableDataType;
        iteration_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(iteration_dt);
    else
        iteration_dt = 'int';
    end

    additionalInputs{end+1} = nasa_toLustre.lustreAst.LustreVar(...
       nasa_toLustre.utils.SLX2LusUtils.iterationVariable(),  iteration_dt);
    IndexMode = ForBlk.IndexMode;
    if strcmp(IndexMode, 'Zero-based')
        iterationValue = 0;
    else
        iterationValue = 1;
    end
    if strcmp(iteration_dt, 'int')
        v = nasa_toLustre.lustreAst.IntExpr(iterationValue);
    elseif strcmp(iteration_dt, 'bool')
        v = nasa_toLustre.lustreAst.BooleanExpr(iterationValue);
    else
        v = nasa_toLustre.lustreAst.RealExpr(iterationValue);
    end
    main_node = main_node.changeArrowExp(...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
        nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr()),...
        nasa_toLustre.lustreAst.RealExpr('0.0')), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
        nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.iterationVariable()),...
        v)));

    main_node_inputs = [node_inputs, inputsMemory, additionalInputs];
    if ~isempty(additionalInputs) || ~isempty(inputsMemory)
        main_node.setInputs(main_node_inputs);
    end
    main_node_outputs = [node_outputs, additionalOutputs];
    if ~isempty(additionalOutputs)
        main_node.setOutputs(main_node_outputs);
    end
    main_node.setLocalVars(new_variables);
    main_node.setLocalContract({});
    % additional node
    node_name = strcat(main_node.getName(), '_iterator');

    iterator_variables = {};
    iterator_body ={};
    iterator_node = nasa_toLustre.lustreAst.LustreNode(...
        '', ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        contract, ...
        iterator_variables, ...
        iterator_body, ...
        false);
    ResetStates = ForBlk.ResetStates;
    isHeld = strcmp(ResetStates, 'held');
    IterationSource = ForBlk.IterationSource;
    if strcmp(IterationSource, 'external')
        return;
    end
    ExternalIncrement = ForBlk.ExternalIncrement;
    if strcmp(ExternalIncrement, 'on')
        return;
    end

    [IterationLimit, ~, status] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(ss_ir, ForBlk, ForBlk.IterationLimit);
    if status
        display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
            ForBlk.IterationLimit, ForBlk.Origin_path), ...
            MsgType.ERROR, 'Constant_To_Lustr', '');
        return;
    end
    if IterationLimit == 0
        % the subsystem does not execute.
        iterator_body = cell(1, numel(node_outputs));
        for i=1:numel(node_outputs)
            var_name = node_outputs{i}.getId();
            var_dt = node_outputs{i}.getDT();
            [~, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(var_dt);
            iterator_body{i} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(var_name), zero);
        end
        iterator_node.setBodyEqs(iterator_body);
        return;
    end

    % define pre memory for inputs
    additionalInputs_with_memory = [inputsMemory, additionalInputs];
    n = numel(additionalInputs_with_memory) - 1;
    for i=1:n
        var_name = additionalInputs_with_memory{i}.getId();
        orig_name = strrep(var_name, '_pre_', '');
        var_dt = additionalInputs_with_memory{i}.getDT();
        [~, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(var_dt);
        if isHeld
            iterator_body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(var_name), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                zero, ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(orig_name))));
        else
            iterator_body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(var_name), ...
                zero);
        end
        iterator_variables{end+1} = additionalInputs_with_memory{i};
    end

    % add additional outputs to variables list.
    iterator_variables = [iterator_variables, additionalOutputs];
    % start creating the call instances
    function [output_names, input_names] = getOuputsInputs(idx)
        fixed_inputs = cellfun(@(x) ...
            nasa_toLustre.lustreAst.VarIdExpr(x.getId()),...
            node_inputs, 'UniformOutput', 0);
        if idx == 1
            fixed_inputs = [fixed_inputs, ...
                cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(x.getId()),...
                inputsMemory, 'UniformOutput', 0)];
        else
            fixed_inputs = [fixed_inputs, ...
                cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(strrep(x.getId(), '_pre_', '')),...
                inputsMemory, 'UniformOutput', 0)];
        end
        if IterationLimit == 1
            additionalInputs_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(x.getId()),...
                additionalInputs, 'UniformOutput', 0);
            output_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(x.getId()),...
                main_node_outputs, 'UniformOutput', 0);
        elseif idx == 1
            additionalInputs_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(x.getId()),...
                additionalInputs, 'UniformOutput', 0);

            output_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(strcat(x.getId(), '_', num2str(idx))),...
                main_node_outputs, 'UniformOutput', 0);
            for vId=1:numel(output_names)
                iterator_variables{end+1} = nasa_toLustre.lustreAst.LustreVar(...
                    output_names{vId}, ...
                    main_node_outputs{vId}.getDT());
            end
        elseif idx == IterationLimit
            additionalInputs_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                strcat(...
                strrep(x.getId(), '_pre_', ''), '_', num2str(idx-1))),...
                additionalInputs, 'UniformOutput', 0);
            output_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(x.getId()),...
                main_node_outputs, 'UniformOutput', 0);
        else
            additionalInputs_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                strcat(...
                strrep(x.getId(), '_pre_', ''), '_', num2str(idx-1))),...
                additionalInputs, 'UniformOutput', 0);
            output_names = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(strcat(x.getId(), '_', num2str(idx))),...
                main_node_outputs, 'UniformOutput', 0);
            for vId=1:numel(output_names)
                iterator_variables{end+1} = nasa_toLustre.lustreAst.LustreVar(...
                    output_names{vId}, ...
                    main_node_outputs{vId}.getDT());
            end
        end
        input_names = [fixed_inputs, additionalInputs_names];
        if strcmp(iteration_dt, 'int')
            input_names{end} = nasa_toLustre.lustreAst.IntExpr(iterationValue);
        elseif strcmp(iteration_dt, 'bool')
            input_names{end} = nasa_toLustre.lustreAst.BooleanExpr(iterationValue);
        else
            input_names{end} = nasa_toLustre.lustreAst.RealExpr(iterationValue);
        end
        iterationValue = iterationValue + 1;


    end
    for i=1:IterationLimit
        [outputs, inputs] = getOuputsInputs(i);
        iterator_body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            outputs, nasa_toLustre.lustreAst.NodeCallExpr(main_node.getName(), inputs));

    end
    iterator_node.setLocalVars(iterator_variables);
    iterator_node.setBodyEqs(iterator_body);

end

