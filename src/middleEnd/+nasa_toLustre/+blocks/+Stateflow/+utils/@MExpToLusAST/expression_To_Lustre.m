function [code, exp_dt, dim] = expression_To_Lustre(BlkObj, tree, parent, blk,...
    data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    
    
    dim = [];
    narginchk(1, 10);
    if isempty(BlkObj), BlkObj = nasa_toLustre.blocks.DummyBlock_To_Lustre; end
    if nargin < 3, parent = []; end
    if nargin < 4, blk = []; end
    if nargin < 5, data_map = containers.Map; end
    if nargin < 6, inputs = {}; end
    if nargin < 7, expected_dt = ''; end
    if nargin < 8, isSimulink = false; end
    if nargin < 9, isStateFlow = false; end
    if nargin < 10, isMatlabFun = false; end
    
    % we assume this function returns cell.
    code = {};
    exp_dt = '';
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
            [code, exp_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.binaryExpression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
        otherwise
            % we use the name of tree_type to call the associated function
            func_name = strcat(tree_type, '_To_Lustre');
            func_handle = str2func(strcat('nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.', func_name));
            try
                [code, exp_dt, dim] = func_handle(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
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
    code = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.convertDT(BlkObj, code, exp_dt, expected_dt);
    if ~isempty(expected_dt), exp_dt = expected_dt; end
    
end
