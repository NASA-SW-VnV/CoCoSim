function outport_process( new_model_base )
%OUTPORT_PROCESS 
% Check if there is an output in the main block

display_msg('Checking output blocks', MsgType.INFO, 'PP', '');

outport_list = find_system(new_model_base,'SearchDepth','1','BlockType','Outport');
if isempty(outport_list)
    display_msg('Model has no outport', MsgType.WARNING, 'PP', '');
else
    display_msg('Model has outport', MsgType.INFO, 'PP', '');
end


end

