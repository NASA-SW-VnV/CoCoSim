function node_name = get_lustre_node_from_Simulink_block_name(trace_file,Simulink_block_name)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           

    if isa(trace_file, 'char')
        DOMNODE = xmlread(trace_file);
        xRoot = DOMNODE.getDocumentElement;
    else
        xRoot = trace_file;
    end
    xml_nodes = xRoot.getElementsByTagName('Node');
    node_name = '';
    for idx_node=0:xml_nodes.getLength-1
        block_name = xml_nodes.item(idx_node).getAttribute('block_name');
        if strcmp(block_name, Simulink_block_name)
            node_name = char(xml_nodes.item(idx_node).getAttribute('node_name'));
            break;
        end

    end
end
        
