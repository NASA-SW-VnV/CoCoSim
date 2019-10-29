function [lus_code, plu_code] = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    lus_lines = {};
    plu_lines = {};
    plu_code = '';
    %opens
    if (LusBackendType.isKIND2(backend) || LusBackendType.isJKIND(backend))
        lus_lines = [lus_lines; ...
            cellfun(@(x) sprintf('include "%s.lus"\n', x), obj.opens, ...
            'UniformOutput', false)];
    else
        lus_lines = [lus_lines; ...
            cellfun(@(x) sprintf('#open <%s>\n', x), obj.opens, ...
            'UniformOutput', false)];
    end
    
    %types
    types = cellfun(@(x) sprintf('%s', x.print(backend)), obj.types, ...
        'UniformOutput', false);
    lus_lines = MatlabUtils.concat(lus_lines, types);
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
