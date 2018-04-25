function Outport_pp( new_model_base )
%OUTPORT_PROCESS 
% Check if there is an output in the main block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display_msg('Checking output blocks', MsgType.INFO, 'PP', '');

outport_list = find_system(new_model_base,'SearchDepth','1','BlockType','Outport');
if isempty(outport_list)
    display_msg('Model has no outport', MsgType.WARNING, 'PP', '');
else
    display_msg('Model has outport', MsgType.INFO, 'PP', '');
end


end

