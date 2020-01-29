%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the 
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
%function [block_name, out_port_nb, dimension] = get_block_name_from_variable_using_xRoot(xRoot, node_name, var_name)
    %this function help to get the name of Simulink block from lustre
    %variable name, using the generated tracability by Cocosim.
    
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

