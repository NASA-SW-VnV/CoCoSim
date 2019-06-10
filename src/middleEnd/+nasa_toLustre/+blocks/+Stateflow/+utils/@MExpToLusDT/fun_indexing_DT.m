function dt = fun_indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    tree_ID = tree.ID;
    switch tree_ID
        case {'abs', 'sgn'}
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.parameters(1), data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
        case 'rem'
            param1 = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.parameters(1), data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
            param2 = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.parameters(2), data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.upperDT(param1, param2);
        case {'sqrt', 'exp', 'log', 'log10',...
                'sin','cos','tan',...
                'asin','acos','atan','atan2', 'power', ...
                'sinh','cosh', ...
                'ceil', 'floor', 'hypot'}
            dt = 'real';
        case {'all', 'any'}
            dt = 'bool';
        otherwise
            dt = simulinkStateflow_Fun_Indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    end
end

function dt = simulinkStateflow_Fun_Indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    global SF_MF_FUNCTIONS_MAP SF_STATES_NODESAST_MAP;
    
    dt = '';
    
    if (isStateFlow || isMatlabFun) && data_map.isKey(tree.ID)
        % A variable in Stateflow
        dt = data_map(tree.ID).LusDatatype;
    elseif (isStateFlow || isMatlabFun)  && SF_MF_FUNCTIONS_MAP.isKey(tree.ID)
        % Graphical function in Stateflow
        nodeAst = SF_MF_FUNCTIONS_MAP(tree.ID);
        outputs = nodeAst.getOutputs();
        dt =  cell(numel(outputs), 1);
        for i=1:numel(outputs)
            d = outputs{i};
            dt{i} = d.getDT();
        end
    elseif isSimulink && strcmp(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if strcmp(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{input_idx}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{1}{1}.getId());
        end
        
    elseif isSimulink &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if strcmp(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{arrayIndex}.getId());
        else
            % we assume "u" is a vector of the same dataType. Which is the
            % case for Fcn/IF/Switch case blocks where isSimulink=true
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.getVarDT(data_map, ...
                inputs{input_number}{1}.getId());
        end
    end
end
