classdef XMLUtils
    %XMLUtils Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        
        %%
        %this function help to get the name of Simulink block from lustre
        %variable name, using the generated tracability by Cocosim.
        function block_name = get_block_name_from_variable_using_xRoot(xRoot, node_name, var_name)
            
            block_name = '';
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
                            return;
                        end
                    end
                    outputs = nodes.item(idx_node).getElementsByTagName('Output');
                    for idx_output=0:outputs.getLength-1
                        output = outputs.item(idx_output);
                        if strcmp(output.getAttribute('variable'), var_name)
                            block = output.getElementsByTagName('block_name');
                            block_name = char(block.item(0).getFirstChild.getData);
                            return;
                        end
                    end
                end
            end
        end
        
        %%
        %%
        function simulink_block_name =...
                get_Simulink_block_from_lustre_node_name(...
                xRoot, ...
                lustre_node_name, ...
                Sim_file_name,...
                new_model_name)
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
        
        %%
        function node_name = get_lustre_node_from_Simulink_block_name(trace_file,Simulink_block_name)
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
    end
    
end

