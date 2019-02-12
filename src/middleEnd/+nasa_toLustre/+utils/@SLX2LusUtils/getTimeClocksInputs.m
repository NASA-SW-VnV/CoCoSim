
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [node_inputs_cell, node_inputs_withoutDT_cell] = ...
        getTimeClocksInputs(blk, main_sampleTime, node_inputs_cell, node_inputs_withoutDT_cell)
    import nasa_toLustre.lustreAst.LustreVar 
    import nasa_toLustre.lustreAst.VarIdExpr
    node_inputs_cell{end + 1} = LustreVar(...
        nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), 'real');
    node_inputs_withoutDT_cell{end+1} = ...
        VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
    node_inputs_cell{end + 1} = LustreVar(...
        nasa_toLustre.utils.SLX2LusUtils.nbStepStr(), 'int');
    node_inputs_withoutDT_cell{end+1} = ...
        VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr());
    % add clocks
    clocks_list = nasa_toLustre.utils.SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
    if ~isempty(clocks_list)
        for i=1:numel(clocks_list)
            node_inputs_cell{end + 1} = LustreVar(...
                clocks_list{i}, 'bool clock');
            node_inputs_withoutDT_cell{end+1} = VarIdExpr(...
                clocks_list{i});
        end
    end
end
