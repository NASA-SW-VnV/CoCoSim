function dt = expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions
    narginchk(1,6);
    if nargin < 2, data_map = containers.Map; end
    if nargin < 3, inputs = {}; end
    if nargin < 4, isSimulink = false; end
    if nargin < 5, isStateFlow = false; end
    if nargin < 6, isMatlabFun = false; end
    dt = '';
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
            dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.binaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
            
        otherwise
            % we use the name of tree_type to call the associated function
            func_name = strcat(tree_type, '_DT');
            func_handle = str2func(strcat('MExpToLusDT.', func_name));
            try
                dt = func_handle(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
            catch me
                dt = '';
                if isequal(me.identifier, 'MATLAB:UndefinedFunction')
                    display_msg(...
                        sprintf(['DataType ERROR: No method with name "%s".'...
                        ' Expression "%s" with type "%s" is not handled yet in MExpToLusDT'],...
                        func_name, tree.text, tree_type), MsgType.WARNING, 'MExpToLusDT.expression_DT', '');
                else
                    display_msg(...
                        sprintf('DataType ERROR for Expression "%s" with type "%s"',...
                        tree.text, tree_type), MsgType.WARNING, 'MExpToLusDT.expression_DT', '');
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.translate', '');
                end
            end
    end
    
end





