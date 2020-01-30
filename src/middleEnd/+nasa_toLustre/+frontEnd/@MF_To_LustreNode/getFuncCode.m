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
function [fun_node,failed ]  = getFuncCode(func, data_map, blkObj, parent, blk)

    global VISITED_VARIABLES;
    VISITED_VARIABLES = {};
    statements = func.statements;
    expected_dt = '';
    isSimulink = false;
    isStateFlow = false;
    isMatlabFun = true;
    variables = {};
    body = {};
    failed = false;
    
    
    
    for i=1:length(statements)
        if isstruct(statements)
            s = statements(i);
        else
            s = statements{i};
        end
        try
            args.blkObj = blkObj;
            args.blk = blk;
            args.parent = parent;
            args.data_map = data_map;
            args.expected_lusDT = expected_dt;
            args.isSimulink = false;
            args.isStateFlow = false;
            args.isMatlabFun = true;
            [lusCode, ~, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(s, args);
            if ~isempty(extra_code)
                [vars, ~] = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getInOutputsFromAction(extra_code, ...
                    false, data_map, s.text, true);
                variables = MatlabUtils.concat(variables, vars);
            end
            [vars, ~] = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getInOutputsFromAction(lusCode, ...
                false, data_map, s.text, true);
            variables = MatlabUtils.concat(variables, vars);
            body = MatlabUtils.concat(body, extra_code, lusCode);
        catch me
            if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                display_msg(me.message, MsgType.WARNING, 'getMFunctionCode', '');
            else
                display_msg(me.getReport(), MsgType.DEBUG, 'getMFunctionCode', '');
            end
            display_msg(sprintf('Statement "%s" failed for block %s', ...
                s.text, HtmlItem.addOpenCmd(blk.Origin_path)),...
                MsgType.WARNING, 'getMFunctionCode', '');
            failed = true;
        end
    end
    [fun_node] = nasa_toLustre.frontEnd.MF_To_LustreNode.getFunHeader(func, blk, data_map);
    node_outputs = fun_node.getOutputs();
    variables = nasa_toLustre.lustreAst.LustreVar.uniqueVars(variables);
    variables = nasa_toLustre.lustreAst.LustreVar.setDiff(variables, node_outputs);
    fun_node.setLocalVars(variables);
    fun_node.setBodyEqs(body);
    fun_node = fun_node.pseudoCode2Lustre(data_map);
end
