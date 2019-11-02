function [lus_code, plu_code] = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global ADD_KIND2_TIMES_ABSTRACTION ADD_KIND2_DIVIDE_ABSTRACTION;
    ADD_KIND2_TIMES_ABSTRACTION = false;
    ADD_KIND2_DIVIDE_ABSTRACTION = false;
    lus_header_lines = {};
    lus_lines = {};
    plu_lines = {};
    plu_code = '';
    %opens
    if (LusBackendType.isKIND2(backend) || LusBackendType.isJKIND(backend))
        lus_header_lines = [lus_header_lines; ...
            cellfun(@(x) sprintf('include "%s.lus"\n', x), obj.opens, ...
            'UniformOutput', false)];
    else
        lus_header_lines = [lus_header_lines; ...
            cellfun(@(x) sprintf('#open <%s>\n', x), obj.opens, ...
            'UniformOutput', false)];
    end
    
    %types
    types = cellfun(@(x) sprintf('%s', x.print(backend)), obj.types, ...
        'UniformOutput', false);
    lus_header_lines = MatlabUtils.concat(lus_header_lines, types);
    if LusBackendType.isPRELUDE(backend)
        plu_lines = [plu_lines; types];
    end
    
    % contracts and nodes
    if LusBackendType.isKIND2(backend)
        nodesList = [obj.nodes, obj.contracts];
    else
        nodesList = obj.nodes;
    end
    
    if LusBackendType.isKIND2(backend)
        call_map = containers.Map('KeyType', 'char', ...
            'ValueType', 'any');
        for i=1:numel(nodesList)
            if isempty(nodesList{i})
                continue;
            end
            call_map(nodesList{i}.name) = nodesList{i}.getNodesCalled();
        end
        % Print nodes in order of calling, because KIND2 Contracts
        % need all nodes used in the contract to be defined first.
        alreadyPrinted = {};
        for i=1:numel(nodesList)
            if isempty(nodesList{i})
                continue;
            end
            [lus_lines, alreadyPrinted] = obj.printWithOrder(...
                nodesList, nodesList{i}.name, call_map, alreadyPrinted, lus_lines, backend);
        end
    else
        for i=1:numel(nodesList)
            if isempty(nodesList{i})
                continue;
            end
            if LusBackendType.isPRELUDE(backend) ...
                    && isa( nodesList{i}, 'nasa_toLustre.lustreAst.LustreNode')
                if hasPreludeOperator(nodesList{i})
                    plu_lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print(backend, true));
                else
                    
                    lus_lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print(LusBackendType.LUSTREC));
                    plu_lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print_preludeImportedNode());
                    
                end
            else
                lus_lines{end+1} = sprintf('%s\n', ...
                    nodesList{i}.print(backend));
            end
        end
    end
    if ADD_KIND2_TIMES_ABSTRACTION
        times_node = getKind2TimesNode();
        lus_header_lines = MatlabUtils.concat(lus_header_lines, times_node);
    end
    if ADD_KIND2_DIVIDE_ABSTRACTION
        divide_node = getKind2TDivideNode();
        lus_header_lines = MatlabUtils.concat(lus_header_lines, divide_node);
    end
    lus_lines = MatlabUtils.concat(lus_header_lines, lus_lines);
    lus_code = MatlabUtils.strjoin(lus_lines, '');
    if LusBackendType.isPRELUDE(backend)
        plu_code = MatlabUtils.strjoin(plu_lines, '');
    end
end

function b = hasPreludeOperator(node)
    if ~isa(node, 'nasa_toLustre.lustreAst.LustreNode')
        b = false;
        return;
    end
    all_body_obj = cellfun(@(x) x.getAllLustreExpr(), node.bodyEqs, 'un',0);
    all_body_obj = MatlabUtils.concat(all_body_obj{:});
    all_objClass = cellfun(@(x) class(x), all_body_obj, 'UniformOutput', false);
    BinaryExprObjects = all_body_obj(strcmp(all_objClass, 'nasa_toLustre.lustreAst.BinaryExpr'));
    operators = cellfun(@(x) x.op, BinaryExprObjects, 'UniformOutput', false);
    b = ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_DIVIDE, operators) ...
        || ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_MULTIPLY, operators) ...
        || ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_OFFSET, operators) ...
        || ismember(nasa_toLustre.lustreAst.BinaryExpr.PRELUDE_FBY, operators);
end

function nodesLines = getKind2TimesNode()
    nodesLines = {};
    nodesLines{end+1} = sprintf('%s\n', 'node kind2_times(x, y: real) returns (z: real) ;');
    nodesLines{end+1} = sprintf('%s\n', 'var abs_x, abs_y, abs_z: real;');
    nodesLines{end+1} = sprintf('%s\n', 'let');
    nodesLines{end+1} = sprintf('%s\n', '   abs_x = if x < 0.0 then -x else x ;');
    nodesLines{end+1} = sprintf('%s\n', '    abs_y = if y < 0.0 then -y else y ;');
    nodesLines{end+1} = sprintf('%s\n', '    abs_z = if z < 0.0 then -z else z ;');
    nodesLines{end+1} = sprintf('%s\n', '    -- Neutral.');
    nodesLines{end+1} = sprintf('%s\n', '    assert (z = y) = ((x = 1.0) or (y = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '    assert (z = x) = ((y = 1.0) or (x = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '    -- Absorbing.');
    nodesLines{end+1} = sprintf('%s\n', '    assert (z = 0.0) = ( (x = 0.0) or (y = 0.0) ) ;');
    nodesLines{end+1} = sprintf('%s\n', '    -- Sign.');
    nodesLines{end+1} = sprintf('%s\n', '    assert (z > 0.0) = (');
    nodesLines{end+1} = sprintf('%s\n', '      ( (x > 0.0) and (y > 0.0) ) or');
    nodesLines{end+1} = sprintf('%s\n', '      ( (x < 0.0) and (y < 0.0) )');
    nodesLines{end+1} = sprintf('%s\n', '    ) ;');
    nodesLines{end+1} = sprintf('%s\n', '    assert (z < 0.0) = (');
    nodesLines{end+1} = sprintf('%s\n', '      ( (x > 0.0) and (y < 0.0) ) or');
    nodesLines{end+1} = sprintf('%s\n', '      ( (x < 0.0) and (y > 0.0) )');
    nodesLines{end+1} = sprintf('%s\n', '    ) ;');
    nodesLines{end+1} = sprintf('%s\n', '    -- Loose proportionality.');
    nodesLines{end+1} = sprintf('%s\n', '    assert (abs_z >= abs_y) = ((abs_x >= 1.0) or (y = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '    assert (abs_z >= abs_x) = ((abs_y >= 1.0) or (x = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '    assert (abs_z <= abs_y) = ((abs_x <= 1.0) or (y = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '    assert (abs_z <= abs_x) = ((abs_y <= 1.0) or (x = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '    z = x * y ;');
    nodesLines{end+1} = sprintf('%s\n', 'tel');
end

function nodesLines = getKind2TDivideNode()
    nodesLines = {};
    nodesLines{end+1} = sprintf('%s\n', 'node kind2_divide(num, den: real) returns (res: real) ;');
    nodesLines{end+1} = sprintf('%s\n', 'var abs_num, abs_den, abs_res: real;');
    nodesLines{end+1} = sprintf('%s\n', 'let');
    nodesLines{end+1} = sprintf('%s\n', ' abs_num = if num < 0.0 then -num else num ;');
    nodesLines{end+1} = sprintf('%s\n', ' abs_den = if den < 0.0 then -den else den ;');
    nodesLines{end+1} = sprintf('%s\n', ' abs_res = if res < 0.0 then -res else res ;');
    nodesLines{end+1} = sprintf('%s\n', 'assert not (den = 0.0) ;');
    nodesLines{end+1} = sprintf('%s\n', '-- Neutral.');
    nodesLines{end+1} = sprintf('%s\n', 'assert (res = num) = ((den = 1.0) or (num = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', 'assert (res = - num) = ((den = - 1.0) or (num = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '-- Absorbing.');
    nodesLines{end+1} = sprintf('%s\n', 'assert (num = 0.0) = (res = 0.0) ;');
    nodesLines{end+1} = sprintf('%s\n', '-- Sign.');
    nodesLines{end+1} = sprintf('%s\n', 'assert (res > 0.0) = (');
    nodesLines{end+1} = sprintf('%s\n', '  ( (num > 0.0) and (den > 0.0) ) or');
    nodesLines{end+1} = sprintf('%s\n', '  ( (num < 0.0) and (den < 0.0) )');
    nodesLines{end+1} = sprintf('%s\n', ') ;');
    nodesLines{end+1} = sprintf('%s\n', 'assert (res < 0.0) = (');
    nodesLines{end+1} = sprintf('%s\n', '  ( (num > 0.0) and (den < 0.0) ) or');
    nodesLines{end+1} = sprintf('%s\n', '  ( (num < 0.0) and (den > 0.0) )');
    nodesLines{end+1} = sprintf('%s\n', ') ;');
    nodesLines{end+1} = sprintf('%s\n', '-- Loose proportionality.');
    nodesLines{end+1} = sprintf('%s\n', 'assert (abs_res >= abs_num) = ((abs_den <= 1.0) or (num = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', 'assert (abs_res <= abs_num) = ((abs_den >= 1.0) or (num = 0.0)) ;');
    nodesLines{end+1} = sprintf('%s\n', '-- Annulation.');
    nodesLines{end+1} = sprintf('%s\n', 'assert (res = 1.0) = (num = den) ;');
    nodesLines{end+1} = sprintf('%s\n', 'assert (res = - 1.0) = (num = - den) ;');
    nodesLines{end+1} = sprintf('%s\n', '  res = num / den ;');
    nodesLines{end+1} = sprintf('%s\n', 'tel');
end