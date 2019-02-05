function simulink_block_name = get_Simulink_block_from_lustre_node_name(...
        trace_root, lustre_node_name, Sim_file_name, new_model_name)
    simulink_block_name = '';
    xRoot = nasa_toLustre.utils.SLX2Lus_Trace.getxRoot(trace_root);
    if isempty(xRoot)
        display_msg('UNKNOWN Variable type trace_root in nasa_toLustre.utils.SLX2Lus_Trace.get_Simulink_block_from_lustre_node_name',...
            MsgType.DEBUG, 'SLX2Lus_Trace', '');
        return;
    end
    xml_nodes = xRoot.getElementsByTagName('Node');
    for idx_node=0:xml_nodes.getLength-1
        lustre_name = xml_nodes.item(idx_node).getAttribute('NodeName');
        if strcmp(lustre_name,lustre_node_name)
            simulink_block_name = char(xml_nodes.item(idx_node).getAttribute('OriginPath'));
            if nargin == 4
                simulink_block_name = regexprep(simulink_block_name,strcat('^',Sim_file_name,'/(\w)'),strcat(new_model_name,'/$1'));
            end
            break;
        end
        
    end
end