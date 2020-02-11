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
function [code, exp_dt, dim, extra_code] = for_block_To_Lustre(tree, args)

    global MFUNCTION_EXTERNAL_NODES
    
    
    code = {};
    exp_dt = '';
    dim = [];
    extra_code = {};
    %%
    should_be_abstracted = false;
    indexes = [];
    index_dt = '';
    try
        [index_expression, index_dt, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
            tree.index_expression, args);
        index_class = unique(cellfun(@(x) class(x), index_expression, 'UniformOutput', 0));
        if length(index_class) == 1 && ...
                (strcmp(index_class{1}, 'nasa_toLustre.lustreAst.IntExpr') || ...
                strcmp(index_class{1}, 'nasa_toLustre.lustreAst.RealExpr'))
            indexes = cellfun(@(x) x.value, index_expression, 'UniformOutput', 1);
        else
            should_be_abstracted = true;
        end
    catch
        should_be_abstracted = true;
    end
    %%
    if ~should_be_abstracted
        try
            [for_node] = nasa_toLustre.utils.MF2LusUtils.getStatementsBlockAsNode(...
                tree, args, 'FOR');
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'for_block_To_Lustre', '');
            should_be_abstracted = true;
        end
    end
    % 
    if should_be_abstracted
        [for_node] = nasa_toLustre.utils.MF2LusUtils.abstract_statements_block(...
            tree, args, 'FOR');
    end
    
    if isempty(for_node)
        return;
    end
    
    [call, oututs_Ids] = for_node.nodeCall();
    if length(oututs_Ids) > 1
        oututs_Ids = nasa_toLustre.lustreAst.TupleExpr(oututs_Ids);
    end
    
    if should_be_abstracted
        code{1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
    else
        index_id = nasa_toLustre.lustreAst.VarIdExpr(tree.index);
        for i = 1:length(indexes)
            index_v = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(indexes(i), index_dt);
            code{end+1} = nasa_toLustre.lustreAst.LustreEq(index_id, index_v);
            code{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
        end
    end
    
    for_node = for_node.pseudoCode2Lustre(args.data_map);
    MFUNCTION_EXTERNAL_NODES{end+1} = for_node;
end

