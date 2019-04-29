classdef MExpToLusAST
    %MEXPTOLUSAST transform a Matlab expression to Lustre AST
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    properties
    end
    methods(Static)
        function [lusCode, status] = translate(BlkObj, exp, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
            
            global SF_MF_FUNCTIONS_MAP ;
            
            
            narginchk(2, 10);
            if isempty(BlkObj), BlkObj = nasa_toLustre.blocks.DummyBlock_To_Lustre; end
            if nargin < 3, parent = []; end
            if nargin < 4, blk = []; end
            if nargin < 5, data_map = containers.Map; end
            if nargin < 6, inputs = {}; end
            if nargin < 7, expected_dt = ''; end
            if nargin < 8, isSimulink = false; end
            if nargin < 9, isStateFlow = false; end
            if nargin < 10, isMatlabFun = false; end
            
            if ~exist('isStateFlow', 'var')
                isStateFlow = false;
            end
            if isempty(blk)
                if isStateFlow
                    blk.Origin_path = 'Stateflow chart';
                else
                    blk.Origin_path = '';
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
                    orig_exp, blk.Origin_path), ...
                    MsgType.ERROR, 'MExpToLusAST.translate', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                return;
            end
            try
                
                lusCode = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
                % transform Stateflow Function call with no outputs to an equation
                if isStateFlow && ~isempty(tree)
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
                        orig_exp, blk.Origin_path), ...
                        MsgType.ERROR, 'MExpToLusAST.translate', '');
                    return;
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                end
            end
            
        end
    end
    methods(Static)
        % use alphabetic order.
        [code, exp_dt] = assignment_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = binaryExpression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = constant_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = expression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = fun_indexing_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = ID_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = matrix_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = parenthesedExpression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = struct_indexing_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
        [code, exp_dt] = unaryExpression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    end
    
    methods(Static)
        % Utils
        
        function [left, right] = inlineOperands(left, right, tree)
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

