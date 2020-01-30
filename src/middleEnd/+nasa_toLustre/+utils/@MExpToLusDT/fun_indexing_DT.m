function [lusDT, slxDT] = fun_indexing_DT(tree, args)

    
    
    tree_ID = tree.ID;
    switch tree_ID
        case {'abs', 'sgn'}
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                tree.parameters(1), args);
        case 'rem'
            [lusDT1, slxDT1] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                tree.parameters(1), args);
            [lusDT2, slxDT2] = nasa_toLustre.utils.MExpToLusDT.expression_DT(...
                tree.parameters(2), args);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.upperDT(...
                lusDT1, lusDT2, slxDT1, slxDT2);
        case {'sqrt', 'exp', 'log', 'log10',...
                'sin','cos','tan',...
                'asin','acos','atan','atan2', 'power', ...
                'sinh','cosh', ...
                'ceil', 'floor', 'hypot'}
            lusDT = 'real';
            slxDT = 'double';
        case {'all', 'any'}
            lusDT = 'bool';
            slxDT = 'boolean';
        otherwise
            [lusDT, slxDT] = simulinkStateflow_Fun_Indexing_DT(tree, args);
    end
end

function [lusDT, slxDT] = simulinkStateflow_Fun_Indexing_DT(tree, args)
    global SF_MF_FUNCTIONS_MAP;% SF_STATES_NODESAST_MAP;
    
    data_map = args.data_map;
    inputs = args.inputs;
    isSimulink = args.isSimulink;
    isStateFlow = args.isStateFlow;
    isMatlabFun = args.isMatlabFun;
    lusDT = '';
    slxDT = '';
    if (isStateFlow || isMatlabFun) && data_map.isKey(tree.ID)
        % A variable in Stateflow
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(...
            data_map, tree.ID);
    elseif (isStateFlow || isMatlabFun)  && SF_MF_FUNCTIONS_MAP.isKey(tree.ID)
        % Graphical function in Stateflow
        nodeAst = SF_MF_FUNCTIONS_MAP(tree.ID);
        outputs = nodeAst.getOutputs();
        lusDT =  cell(numel(outputs), 1);
        for i=1:numel(outputs)
            d = outputs{i};
            lusDT{i} = d.getDT();
        end
        slxDT = LusValidateUtils.get_slx_dt(lusDT);
    elseif isSimulink && strcmp(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if strcmp(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{input_idx}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{1}.getId());
        end
        
    elseif isSimulink &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if strcmp(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{arrayIndex}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{1}.getId());
        end
    end
end
