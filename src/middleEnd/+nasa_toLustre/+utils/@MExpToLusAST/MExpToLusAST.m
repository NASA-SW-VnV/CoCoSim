%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MExpToLusAST
    %MEXPTOLUSAST transform a Matlab expression to Lustre AST

    
    properties
    end
    methods(Static)
        % use alphabetic order.
        [code, lusDT, dim, extra_code] = assignment_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = binaryExpression_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = clear_exp_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = colonExpression_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = constant_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = end_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = expression_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = for_block_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = fun_indexing_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = ID_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = if_block_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = matrix_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = parenthesedExpression_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = struct_indexing_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = transpose_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = unaryExpression_To_Lustre(tree, args)
        [code, lusDT, dim, extra_code] = while_block_To_Lustre(tree, args)
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
            %extra_code = {};
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
                tree = coco_nasa_utils.MatlabUtils.getExpTree(exp);
            catch me
                status = 1;
                display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                    orig_exp, args.blk.Origin_path), ...
                    MsgType.ERROR, 'MExpToLusAST.translate', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                return;
            end
            try
                
                [lusCode, ~, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree, args);
                lusCode = coco_nasa_utils.MatlabUtils.concat(lusCode, extra_code);
                
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

