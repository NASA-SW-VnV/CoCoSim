function err = AlgebraicLoops_pp( new_model_base )
%ALGEBRAIC_LOOPS_PROCESS raises algebric loops error.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
warning off;
evalin('base',code_on);

try
    loops = Simulink.BlockDiagram.getAlgebraicLoops(new_model_base);
catch
    loops = [];
end
code_on=sprintf('%s([], [], [], ''term'')', new_model_base);
evalin('base',code_on);
if numel(loops) > 0
    err = 1;
    display_msg('Please fix these algebric loops (maybe by adding unit Delays)',...
        MsgType.ERROR, 'AlgebraicLoops_pp', '')
    return;
end
% warning on;
end

