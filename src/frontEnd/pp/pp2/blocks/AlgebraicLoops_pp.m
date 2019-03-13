function [status, errors_msg] = AlgebraicLoops_pp( new_model_base )
%ALGEBRAIC_LOOPS_PROCESS raises algebric loops error.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};
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
    status = 1;
    errors_msg{end + 1} = sprintf('AlgebraicLoops pre-process has failed for %s (maybe by adding unit Delays)', new_model_base);
    return;
end
% warning on;
end

