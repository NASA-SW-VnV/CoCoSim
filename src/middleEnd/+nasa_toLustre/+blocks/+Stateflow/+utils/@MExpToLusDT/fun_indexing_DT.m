function dt = fun_indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow)
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    tree_ID = tree.ID;
    switch tree_ID
        case {'abs', 'sgn'}
            dt = MExpToLusDT.expression_DT(tree.parameters(1), data_map, inputs, isSimulink, isStateFlow);
        case 'rem'
            param1 = MExpToLusDT.expression_DT(tree.parameters(1), data_map, inputs, isSimulink, isStateFlow);
            param2 = MExpToLusDT.expression_DT(tree.parameters(2), data_map, inputs, isSimulink, isStateFlow);
            dt = MExpToLusDT.upperDT(param1, param2);
        case {'sqrt', 'exp', 'log', 'log10',...
                'sin','cos','tan',...
                'asin','acos','atan','atan2', 'power', ...
                'sinh','cosh', ...
                'ceil', 'floor', 'hypot'}
            dt = 'real';
        case {'all', 'any'}
            dt = 'bool';
        otherwise
            dt = simulinkStateflow_Fun_Indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow);
    end
end

function dt = simulinkStateflow_Fun_Indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow)
    global SF_GRAPHICALFUNCTIONS_MAP SF_STATES_NODESAST_MAP;
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    dt = '';
    
    if isStateFlow && data_map.isKey(tree.ID)
        % A variable in Stateflow
        dt = data_map(tree.ID).LusDatatype;
    elseif isStateFlow && SF_GRAPHICALFUNCTIONS_MAP.isKey(tree.ID)
        % Graphical function in Stateflow
        func = SF_GRAPHICALFUNCTIONS_MAP(tree.ID);
        sfNodename = nasa_toLustre.frontEnd.SF_To_LustreNode.getUniqueName(func);
        nodeAst = SF_STATES_NODESAST_MAP(sfNodename);
        outputs = nodeAst.getOutputs();
        dt =  cell(numel(outputs), 1);
        for i=1:numel(outputs)
            d = outputs{i};
            dt{i} = d.getDT();
        end
    elseif isSimulink && isequal(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if isequal(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            dt = MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{input_idx}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            dt = MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{1}.getId());
        end
        
    elseif isSimulink &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if isequal(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            dt = MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{arrayIndex}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            dt = MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{1}.getId());
        end
    end
end