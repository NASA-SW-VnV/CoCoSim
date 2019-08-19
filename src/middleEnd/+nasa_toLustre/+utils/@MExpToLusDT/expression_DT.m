function [lusDT, slxDT] = expression_DT(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions
    narginchk(1,6);
    if ~isfield(args, 'data_map'), args.data_map = containers.Map; end
    if ~isfield(args, 'inputs'), args.inputs = {}; end
    if ~isfield(args, 'isLeft'), args.isLeft = false; end
    if ~isfield(args, 'isSimulink'), args.isSimulink = false; end
    if ~isfield(args, 'isStateFlow'), args.isStateFlow = false; end
    if ~isfield(args, 'isMatlabFun'), args.isMatlabFun = false; end
    lusDT = '';
    slxDT = '';
    if isempty(tree)
        return;
    end
    if iscell(tree) && numel(tree) == 1
        tree = tree{1};
    end
    if ~isfield(tree, 'type')
        return;
    end
    tree_type = tree.type;
    switch tree_type
        case {'relopAND', 'relopelAND',...
                'relopOR', 'relopelOR', ...
                'relopGL', 'relopEQ_NE', ...
                'plus_minus', 'mtimes', 'times', ...
                'mrdivide', 'mldivide', 'rdivide', 'ldivide', ...
                'mpower', 'power'}
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.binaryExpression_DT(...
                tree, args);
            
        otherwise
            % we use the name of tree_type to call the associated function
            func_name = strcat(tree_type, '_DT');
            func_handle = str2func(strcat('nasa_toLustre.utils.MExpToLusDT.', func_name));
            try
                [lusDT, slxDT] = func_handle(tree, args);
            catch me
                lusDT = '';
                slxDT = '';
                display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                if strcmp(me.identifier, 'MATLAB:UndefinedFunction')
                    display_msg(...
                        sprintf(['DataType ERROR: No method with name "%s".'...
                        ' Expression "%s" with type "%s" is not handled yet in MExpToLusDT'],...
                        func_name, tree.text, tree_type), MsgType.WARNING, 'MExpToLusDT.expression_DT', '');
                else
                    display_msg(...
                        sprintf('DataType ERROR for Expression "%s" with type "%s"',...
                        tree.text, tree_type), MsgType.WARNING, 'MExpToLusDT.expression_DT', '');
                end
            end
    end
    
end





