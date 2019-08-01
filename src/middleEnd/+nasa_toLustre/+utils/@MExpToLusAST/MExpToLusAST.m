classdef MExpToLusAST
    %MEXPTOLUSAST transform a Matlab expression to Lustre AST
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    methods(Static)
        % use alphabetic order.
        [code, lusDT, dim] = assignment_To_Lustre(tree, args)
        [code, lusDT, dim] = binaryExpression_To_Lustre(tree, args)
        [code, lusDT, dim] = colonExpression_To_Lustre(tree, args)
        [code, lusDT, dim] = constant_To_Lustre(tree, args)
        [code, lusDT, dim] = end_To_Lustre(tree, args)
        [code, lusDT, dim] = expression_To_Lustre(tree, args)
        [code, lusDT, dim] = for_block_To_Lustre(tree, args)
        [code, lusDT, dim] = fun_indexing_To_Lustre(tree, args)
        [code, lusDT, dim] = ID_To_Lustre(tree, args)
        [code, lusDT, dim] = if_block_To_Lustre(tree, args)
        [code, lusDT, dim] = matrix_To_Lustre(tree, args)
        [code, lusDT, dim] = parenthesedExpression_To_Lustre(tree, args)
        [code, lusDT, dim] = struct_indexing_To_Lustre(tree, args)
        [code, lusDT, dim] = transpose_To_Lustre(tree, args)
        [code, lusDT, dim] = unaryExpression_To_Lustre(tree, args)
        [code, lusDT, dim] = while_block_To_Lustre(tree, args)
    end
    
    methods(Static)
        function [lusCode, status] = translate(exp, args)
            
            global SF_MF_FUNCTIONS_MAP ;
            
            
            narginchk(2, 2);

            
            if ~isfield(args, 'blkObj'), args.blkObj = nasa_toLustre.blocks.DummyBlock_To_Lustre; end
            if ~isfield(args, 'data_map'), args.data_map = containers.Map; end
            if ~isfield(args, 'inputs'), args.inputs = {}; end
            if ~isfield(args, 'isLeft'), args.isLeft = false; end
            if ~isfield(args, 'isSimulink'), args.isSimulink = false; end
            if ~isfield(args, 'isStateFlow'), args.isStateFlow = false; end
            if ~isfield(args, 'isMatlabFun'), args.isMatlabFun = false; end
            if ~isfield(args, 'expected_lusDT'), args.expected_lusDT = ''; end
            if ~isfield(args, 'blk'), args.blk = []; end
            if ~isfield(args, 'parent'), args.parent = []; end
            if isempty(args.blk)
                if args.isStateFlow
                    args.blk.Origin_path = 'Stateflow chart';
                else
                    args.blk.Origin_path = '';
                end
            end
            status = 0;
            lusCode = {};
            if isempty(exp)
                return;
            end
            %pre-process exp
            orig_exp = exp;
            exp = strrep(orig_exp, '!=', '~=');
            % adapt C access array u[1] to Matlab syntax u(1)
            exp = regexprep(exp, '(\w)\[([^\[\]])+\]', '$1($2)');
            %get exp IR
            try
                tree = MatlabUtils.getExpTree(exp);
            catch me
                status = 1;
                display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                    orig_exp, args.blk.Origin_path), ...
                    MsgType.ERROR, 'MExpToLusAST.translate', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                return;
            end
            try
                
                lusCode = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree, args);
                % transform Stateflow Function call with no outputs to an equation
                if args.isStateFlow && ~isempty(tree)
                    if iscell(tree) && numel(tree) == 1
                        tree = tree{1};
                    end
                    if isfield(tree, 'type') && ...
                            strcmp(tree.type, 'fun_indexing') &&...
                            isKey(SF_MF_FUNCTIONS_MAP, tree.ID)
                        actionNodeAst = SF_MF_FUNCTIONS_MAP(tree.ID);
                        [~, oututs_Ids] = actionNodeAst.nodeCall();
                        lusCode{1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids,...
                            lusCode{1});
                    end
                end
            catch me
                status = 1;
                
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    display_msg(me.message, MsgType.ERROR, 'MExpToLusAST.translate', '')
                    display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                        orig_exp, args.blk.Origin_path), ...
                        MsgType.ERROR, 'MExpToLusAST.translate', '');
                    return;
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                end
            end
            
        end
    end
    
    
    methods(Static)
        % Utils
        
        function [left, right, failed] = inlineOperands(left, right, tree)
            failed = false;
            if isempty(left) && isempty(right)
                return;
            end
            if numel(right) == 1 && numel(left) > 1
                right = arrayfun(@(x) right{1}, ...
                    (1:numel(left)), 'UniformOutput', false);
            elseif numel(left) == 1 && numel(right) > 1
                left = arrayfun(@(x) left{1}, ...
                    (1:numel(right)), 'UniformOutput', false);
            elseif numel(left) ~= numel(right)
                failed = true;
                if nargin < 3 || isempty(tree)
                    return;
                end
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Expression "%s" has incompatible dimensions. First parameter width is %d where the second parameter width is %d',...
                    tree.text, numel(left), numel(right));
                throw(ME);
            end
            
        end
        
    end
end

