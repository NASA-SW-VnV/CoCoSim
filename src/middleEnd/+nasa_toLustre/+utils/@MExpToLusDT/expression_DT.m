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
function [lusDT, slxDT] = expression_DT(tree, args)

    
    
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





