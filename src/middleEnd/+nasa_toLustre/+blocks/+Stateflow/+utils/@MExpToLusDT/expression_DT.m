function dt = expression_DT(tree, data_map, inputs, isSimulink, isStateFlow)
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions
    narginchk(1,5);
    if nargin < 2, data_map = containers.Map; end
    if nargin < 3, inputs = {}; end
    if nargin < 4, isSimulink = false; end
    if nargin < 5, isStateFlow = false; end
    
    dt = '';
    if isempty(tree)
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
            dt = MExpToLusDT.binaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow);
            
        otherwise
            % we use the name of tree_type to call the associated function
            func_name = strcat(tree_type, '_DT');
            func_handle = str2func(strcat('MExpToLusDT.', func_name));
            try
                dt = func_handle(tree, data_map, inputs, isSimulink, isStateFlow);
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





