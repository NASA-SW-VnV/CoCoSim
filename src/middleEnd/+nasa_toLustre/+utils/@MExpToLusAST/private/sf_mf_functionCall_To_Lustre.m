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
function [code, extra_code] = sf_mf_functionCall_To_Lustre(tree, args)

    % G    
    
    global SF_MF_FUNCTIONS_MAP ;
    extra_code = {};
    if isa(tree.parameters, 'struct')
        parameters = arrayfun(@(x) x, tree.parameters, 'UniformOutput', false);
    else
        parameters = tree.parameters;
    end
    actionNodeAst = SF_MF_FUNCTIONS_MAP(tree.ID);
    node_inputs = actionNodeAst.getInputs();
    if isempty(parameters)
        [call, ~] = actionNodeAst.nodeCall();
        code = call;
    else
        params_dt =  cellfun(@(x) x.getDT(), node_inputs, 'UniformOutput', 0);
        params_ast = {};
        dt_idx = 1;
        for i=1:numel(parameters)
            args.expected_lusDT = params_dt{dt_idx};
            [f_args, dt, ~, extra_code_i] = ...
                nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                parameters{i}, args);
            extra_code = MatlabUtils.concat(extra_code, extra_code_i);
            f_args = nasa_toLustre.utils.MExpToLusDT.convertDT(args.blkObj, f_args, dt, params_dt{dt_idx});
            dt_idx = dt_idx + length(f_args);
            params_ast = MatlabUtils.concat(params_ast, f_args);
        end
        if numel(node_inputs) == numel(params_ast)
            code = nasa_toLustre.lustreAst.NodeCallExpr(actionNodeAst.getName(), params_ast);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" expected %d parameters but got %d',...
                tree.ID, numel(node_inputs), numel(tree.parameters));
            throw(ME);
        end
    end
    
end
