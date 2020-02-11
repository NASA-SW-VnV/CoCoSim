%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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