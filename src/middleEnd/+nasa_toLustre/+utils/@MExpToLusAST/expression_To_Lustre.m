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
function [code, exp_dt, dim, extra_code] = expression_To_Lustre(tree, args)
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions

    
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
                        ' Expression "%s" with type "%s" is not handled yet in CoCoSim Parser. Block %s.'],...
                        func_name, tree.text, tree_type, HtmlItem.addOpenCmd(args.blk.Origin_path));
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
    if length(dim) == 1 && dim == 1, dim = [1,1]; end
end
