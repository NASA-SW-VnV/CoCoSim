function simulink_block_name =...
        get_Simulink_block_from_lustre_node_name(...
        traceability, ...
        lustre_node_name, ...
        Sim_file_name,...
        new_model_name)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
    
    if ischar(traceability)
        DOMNODE = xmlread(traceability);
        xRoot = DOMNODE.getDocumentElement;
    elseif isa(traceability, 'XML_Trace')
        xRoot = traceability.traceRootNode;
    else
        xRoot = traceability;
    end
    simulink_block_name = '';
    xml_nodes = xRoot.getElementsByTagName('Node');
    for idx_node=0:xml_nodes.getLength-1
        lustre_name = xml_nodes.item(idx_node).getAttribute('node_name');
        if strcmp(lustre_name,lustre_node_name)
            simulink_block_name = char(xml_nodes.item(idx_node).getAttribute('block_name'));
            if nargin == 4
                simulink_block_name = regexprep(simulink_block_name,strcat('^',Sim_file_name,'/(\w)'),strcat(new_model_name,'/$1'));
            end
            break;
        end

    end
end

