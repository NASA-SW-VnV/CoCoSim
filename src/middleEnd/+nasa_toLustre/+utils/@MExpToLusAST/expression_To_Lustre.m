function [code, exp_dt, dim, extra_code] = expression_To_Lustre(tree, args)
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    narginchk(2,2);
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
    if ~isfield(args, 'if_cond'), args.if_cond = []; end
    % we assume this function returns cell.
    code = {};
    extra_code = {};
    exp_dt = '';
    dim = [];
    if isempty(tree)
        return;
    end
    if iscell(tree) && numel(tree) == 1
        tree = tree{1};
    end
    if ~isfield(tree, 'type')
        if isfield(tree, 'text')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Parser Failed: Matlab AST of expression "%s" has no attribute type.',...
                tree.text);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Parser Failed: Matlab AST has no attribute type.');
        end
        throw(ME);
    end
    tree_type = tree.type;
    switch tree_type
        case {'relopAND', 'relopelAND',...
                'relopOR', 'relopelOR', ...
                'relopGL', 'relopEQ_NE', ...
                'plus_minus', 'mtimes', 'times', ...
                'mrdivide', 'mldivide', 'rdivide', 'ldivide', ...
                'mpower', 'power'}
            [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.binaryExpression_To_Lustre(tree, args);
        case {'COLON', 'colonExpression'}
            [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.colonExpression_To_Lustre(tree, args);
        otherwise
            % we use the name of tree_type to call the associated function
            func_name = strcat(tree_type, '_To_Lustre');
            func_handle = str2func(strcat('nasa_toLustre.utils.MExpToLusAST.', func_name));
            try
                [code, exp_dt, dim, extra_code] = func_handle(tree, args);
            catch me
                if strcmp(me.identifier, 'MATLAB:UndefinedFunction')
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.expression_To_Lustre', '');
                    ME = MException('COCOSIM:TREE2CODE', ...
                        ['Parser ERROR: No method with name "%s".'...
                        ' Expression "%s" with type "%s" is not handled yet in CoCoSim Parser'],...
                        func_name, tree.text, tree_type);
                    throw(ME);
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.expression_To_Lustre', '');
                    ME = MException('COCOSIM:TREE2CODE', ...
                        'Parser ERROR for Expression "%s" with type "%s"',...
                        tree.text, tree_type);
                    throw(ME);
                end
            end
    end
    % convert tree DT to what is expected.
%     try
    [code, output_dt] = nasa_toLustre.utils.MExpToLusDT.convertDT(args.blkObj, code, exp_dt, args.expected_lusDT);
%     catch me
%         me
%     end
    if ~isempty(output_dt), exp_dt = output_dt; end
    
end
