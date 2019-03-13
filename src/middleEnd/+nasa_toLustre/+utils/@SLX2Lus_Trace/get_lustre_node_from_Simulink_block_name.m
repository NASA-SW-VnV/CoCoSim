%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function node_name = get_lustre_node_from_Simulink_block_name(trace_root,Simulink_block_name)
    node_name = '';
    xRoot = nasa_toLustre.utils.SLX2Lus_Trace.getxRoot(trace_root);
    if isempty(xRoot)
        display_msg('UNKNOWN Variable type trace_root in nasa_toLustre.utils.SLX2Lus_Trace.get_lustre_node_from_Simulink_block_name',...
            MsgType.DEBUG, 'SLX2Lus_Trace', '');
        return;
    end
    xml_nodes = xRoot.getElementsByTagName('Node');
    
    for idx_node=0:xml_nodes.getLength-1
        block_name = xml_nodes.item(idx_node).getAttribute('OriginPath');
        if strcmp(block_name, Simulink_block_name)
            node_name = char(xml_nodes.item(idx_node).getAttribute('NodeName'));
            break;
        end
        
    end
end
