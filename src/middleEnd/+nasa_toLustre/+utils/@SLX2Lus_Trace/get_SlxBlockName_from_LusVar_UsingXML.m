%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [block_name, port, width, index, isInsideContract, isNotInSimulink, portType] = ...
        get_SlxBlockName_from_LusVar_UsingXML(xml_trace, node_name, var_name)
    
    block_name = '';
    index = [];
    width = [];
    port = [];
    portType = '';
    isNotInSimulink = [];
    isInsideContract = [];
    xRoot = nasa_toLustre.utils.SLX2Lus_Trace.getxRoot(xml_trace);
    if isempty(xRoot)
        display_msg('UNKNOWN Variable type trace_root in nasa_toLustre.utils.SLX2Lus_Trace.get_SlxBlockName_from_LusVar_UsingXML',...
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
                if strcmp(input.getAttribute('VariableName'), var_name)
                    [block_name, port, width, index, isInsideContract, ...
                        isNotInSimulink, portType] = ...
                        getParamValues(input);
                    return;
                end
            end
            outputs = nodes.item(idx_node).getElementsByTagName('Outport');
            for idx_output=0:outputs.getLength-1
                output = outputs.item(idx_output);
                if strcmp(output.getAttribute('VariableName'), var_name)
                    [block_name, port, width, index, isInsideContract, ...
                        isNotInSimulink, portType] = ...
                        getParamValues(output);
                    return;
                end
            end
            vars = nodes.item(idx_node).getElementsByTagName('Variable');
            for idx_var=0:vars.getLength-1
                var = vars.item(idx_var);
                v_name_i = var.getAttribute('VariableName');
                if strcmp(v_name_i, var_name)
                    [block_name, port, width, index, isInsideContract, ...
                        isNotInSimulink, portType] = ...
                        getParamValues(var);
                    return;
                end
            end
        end
    end
end

function [block_name, port, width, index, isInsideContract, isNotInSimulink, portType] = ...
        getParamValues(input)
    isNotInSimulink = str2double(char(input.getAttribute('IsNotInSimulink')));
    isInsideContract = str2double(char(input.getAttribute('IsInsideContract')));
    block_name = char(input.getElementsByTagName('OriginPath').item(0).getTextContent());
    index = str2double(input.getElementsByTagName('Index').item(0).getTextContent());
    width = str2double(input.getElementsByTagName('Width').item(0).getTextContent());
    port = str2double(input.getElementsByTagName('PortNumber').item(0).getTextContent());
    portType = char(input.getElementsByTagName('PortType').item(0).getTextContent());
end