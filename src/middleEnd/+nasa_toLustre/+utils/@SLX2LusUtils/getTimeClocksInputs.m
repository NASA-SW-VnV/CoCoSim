
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function [node_inputs_cell, node_inputs_withoutDT_cell] = ...
        getTimeClocksInputs(blk, main_sampleTime, node_inputs_cell, node_inputs_withoutDT_cell)
     
    
    node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
        nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), 'real');
    node_inputs_withoutDT_cell{end+1} = ...
        nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
    node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
        nasa_toLustre.utils.SLX2LusUtils.nbStepStr(), 'int');
    node_inputs_withoutDT_cell{end+1} = ...
        nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr());
    % add clocks
    clocks_list = nasa_toLustre.utils.SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
    if ~isempty(clocks_list)
        % add clocks in the begining of the inputs
        clocks_var = cellfun(@(x) ...
            nasa_toLustre.lustreAst.LustreVar(x, 'bool clock'), ...
            clocks_list, 'UniformOutput', 0);
        node_inputs_cell = [clocks_var, node_inputs_cell];
        clocks_id = cellfun(@(x) ...
            nasa_toLustre.lustreAst.VarIdExpr(x), ...
            clocks_list, 'UniformOutput', 0);
        node_inputs_withoutDT_cell = [clocks_id, node_inputs_withoutDT_cell];
    end
end
