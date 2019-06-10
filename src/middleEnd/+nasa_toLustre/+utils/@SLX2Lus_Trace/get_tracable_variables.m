%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% get variables +inputs + outputs names of a node
function variables_names = get_tracable_variables(xml_trace, node_name)
    
    variables_names = {};
    xRoot = nasa_toLustre.utils.SLX2Lus_Trace.getxRoot(xml_trace);
    if isempty(xRoot)
        display_msg('UNKNOWN Variable type trace_root in nasa_toLustre.utils.SLX2Lus_Trace.get_tracable_variables',...
            MsgType.DEBUG, 'SLX2Lus_Trace', '');
        return;
    end
    nodes = xRoot.getElementsByTagName('Node');
    for idx_node=0:nodes.getLength-1
        block_name_node = nodes.item(idx_node).getAttribute('NodeName');
        if strcmp(block_name_node, node_name)
            inputs = nodes.item(idx_node).getElementsByTagName('Inport');
            for idx_input=0:inputs.getLength-1
                input = inputs.item(idx_input);
                variables_names{end + 1} = ...
                    char(input.getAttribute('VariableName'));
            end
            outputs = nodes.item(idx_node).getElementsByTagName('Outport');
            for idx_output=0:outputs.getLength-1
                output = outputs.item(idx_output);
                variables_names{end + 1} = ...
                    char(output.getAttribute('VariableName'));
            end
            variables = nodes.item(idx_node).getElementsByTagName('Variable');
            for idx_var=0:variables.getLength-1
                var = variables.item(idx_var);
                variables_names{end + 1} = ...
                    char(var.getAttribute('VariableName'));
            end
        end
    end
end
