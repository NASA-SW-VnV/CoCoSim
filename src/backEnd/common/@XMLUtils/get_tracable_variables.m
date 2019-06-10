function variables_names = get_tracable_variables(xRoot, node_name)
    % get variables +inputs + outputs names of a node

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    variables_names = {};
    nodes = xRoot.getElementsByTagName('Node');
    for idx_node=0:nodes.getLength-1
        block_name_node = nodes.item(idx_node).getAttribute('node_name');
        if strcmp(block_name_node, node_name)
            inputs = nodes.item(idx_node).getElementsByTagName('Input');
            for idx_input=0:inputs.getLength-1
                input = inputs.item(idx_input);
                variables_names{numel(variables_names) + 1} = ...
                    char(input.getAttribute('variable'));
            end
            outputs = nodes.item(idx_node).getElementsByTagName('Output');
            for idx_output=0:outputs.getLength-1
                output = outputs.item(idx_output);
                variables_names{numel(variables_names) + 1} = ...
                    char(output.getAttribute('variable'));
            end
            variables = nodes.item(idx_node).getElementsByTagName('Variable');
            for idx_var=0:variables.getLength-1
                var = variables.item(idx_var);
                variables_names{numel(variables_names) + 1} = ...
                    char(var.getAttribute('variable'));
            end
        end
    end
end

