function [IDs] = getAssignmentLeftIDs(tree)
    IDs = {};
    if isempty(tree)
        return;
    end
    if iscell(tree) && numel(tree) == 1
        tree = tree{1};
    end
    if ~isfield(tree, 'type')
        if isfield(tree, 'text')
            ME = MException('COCOSIM:TREE2CODE', ...
                'getAssignmentLeftIDs Failed: Matlab AST of expression "%s" has no attribute type.',...
                tree.text);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'getAssignmentLeftIDs Failed: Matlab AST has no attribute type.');
        end
        throw(ME);
    end
    if strcmp(tree.type, 'assignment')
        tree = tree.leftExp;
    end
    tree_type = tree.type;
    %%
    switch tree_type
        case 'struct_indexing'
            IDs = nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree.leftExp);
            
        case 'fun_indexing'
            if ischar(tree.ID)
                IDs{1} = tree.ID;
            else
                IDs = nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree.ID);
            end
            
        case 'cell_indexing'
            IDs{1} = tree.ID;
            
        case 'parenthesedExpression'
            IDs = nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(tree.expression);
            
        case 'ID'
            IDs{1} = tree.name;
            
        case 'matrix'
            % matrix should have one row if it is on the left of an assignment
            if isstruct(tree.rows)
                rows = arrayfun(@(x) x, tree.rows, 'UniformOutput', false);
            else
                rows = tree.rows;
            end
            
            nb_rows = numel(rows);
            if nb_rows > 1
                ME = MException('COCOSIM:TREE2CODE', ...
                    'getAssignmentLeftIDs Failed: Unexpected expression "%s" on the left side of an assignment.',...
                    tree.text);
                throw(ME);
            end
            nb_columns = numel(rows{1});
            for j=1:nb_columns
                    v = rows{1}(j);
                    IDs = MatlabUtils.concat(IDs, ...
                        nasa_toLustre.utils.MF2LusUtils.getAssignmentLeftIDs(v));
            end
    end
end

