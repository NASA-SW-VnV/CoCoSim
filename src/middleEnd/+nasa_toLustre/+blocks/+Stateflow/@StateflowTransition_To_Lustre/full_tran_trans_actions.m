
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%transition actions
function [body, outputs, inputs] = ...
        full_tran_trans_actions(transitions, trans_cond)
    global SF_STATES_NODESAST_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    body = {};
    outputs = {};
    inputs = {};
    nbTrans = numel(transitions);

    % Execute all transition actions along the transition full path.
    for i=1:nbTrans
        t = transitions{i};
        source = t.Source;%Path of the source
        transTransActionNodeName = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTranActionNodeName(t, ...
            source);
        if isKey(SF_STATES_NODESAST_MAP, transTransActionNodeName)
            %transition Action exists.
            actionNodeAst = SF_STATES_NODESAST_MAP(transTransActionNodeName);
            [call, oututs_Ids] = actionNodeAst.nodeCall();
            if isempty(trans_cond)
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, call);
                outputs = [outputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getInputs()];
            else
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(oututs_Ids, ...
                    nasa_toLustre.lustreAst.IteExpr(trans_cond, call, nasa_toLustre.lustreAst.TupleExpr(oututs_Ids)));
                outputs = [outputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getInputs()];
            end
        end
    end
end
