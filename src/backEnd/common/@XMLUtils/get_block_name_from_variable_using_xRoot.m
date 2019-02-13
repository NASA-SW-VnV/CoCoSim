function [block_name, out_port_nb, dimension] = get_block_name_from_variable_using_xRoot(xRoot, node_name, var_name)
    %this function help to get the name of Simulink block from lustre
    %variable name, using the generated tracability by Cocosim.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    block_name = '';
    out_port_nb = '';
    dimension = '';
    nodes = xRoot.getElementsByTagName('Node');
    for idx_node=0:nodes.getLength-1
        block_name_node = nodes.item(idx_node).getAttribute('node_name');
        if strcmp(block_name_node, node_name)
            inputs = nodes.item(idx_node).getElementsByTagName('Input');
            for idx_input=0:inputs.getLength-1
                input = inputs.item(idx_input);
                if strcmp(input.getAttribute('variable'), var_name)
                    block = input.getElementsByTagName('block_name');
                    block_name = char(block.item(0).getFirstChild.getData);
                    out_port_nb_xml = input.getElementsByTagName('out_port_nb');
                    out_port_nb = char(out_port_nb_xml.item(0).getFirstChild.getData);
                    dimension_xml = input.getElementsByTagName('dimension');
                    dimension = char(dimension_xml.item(0).getFirstChild.getData);
                    return;
                end
            end
            outputs = nodes.item(idx_node).getElementsByTagName('Output');
            for idx_output=0:outputs.getLength-1
                output = outputs.item(idx_output);
                if strcmp(output.getAttribute('variable'), var_name)
                    block = output.getElementsByTagName('block_name');
                    block_name = char(block.item(0).getFirstChild.getData);
                    out_port_nb_xml = output.getElementsByTagName('out_port_nb');
                    if out_port_nb_xml.getLength == 0
                        out_port_nb_xml = output.getElementsByTagName('in_port_nb');
                    end
                    if out_port_nb_xml.getLength == 0
                        dimension = '';
                        continue;
                    end
                    out_port_nb = char(out_port_nb_xml.item(0).getFirstChild.getData);
                    dimension_xml = output.getElementsByTagName('dimension');
                    dimension = char(dimension_xml.item(0).getFirstChild.getData);
                    return;
                end
            end
            vars = nodes.item(idx_node).getElementsByTagName('Variable');
            for idx_var=0:vars.getLength-1
                var = vars.item(idx_var);
                if strcmp(var.getAttribute('variable'), var_name)
                    block = var.getElementsByTagName('block_name');
                    block_name = char(block.item(0).getFirstChild.getData);
                    out_port_nb_xml = var.getElementsByTagName('out_port_nb');
                    out_port_nb = char(out_port_nb_xml.item(0).getFirstChild.getData);
                    dimension_xml = var.getElementsByTagName('dimension');
                    dimension = char(dimension_xml.item(0).getFirstChild.getData);
                    return;
                end
            end
        end
    end
end

