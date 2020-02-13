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

function node_process(new_model_name, nodes, node, node_block_path, block_pos, xml_trace)
    node_name = coco_nasa_utils.SLXUtils.adapt_block_name(node);
    display_msg(...
        sprintf('Processing node "%s" ',node_name),...
        MsgType.INFO, 'lus2slx', '');
    x2 = 200;
    y2= -50;
    if coco_nasa_utils.MatlabUtils.startsWith(node, '_')
        % Simulink read json : _max_real is read as x_max_real
        node = strcat('x', node);
    end
    if ~isempty(xml_trace)
        xml_trace.create_Node_Element(node_block_path,  nodes.(node).original_name);
    end
    add_block('built-in/Subsystem', node_block_path);%,...
    %             'TreatAsAtomicUnit', 'on');
    set_param(node_block_path, 'Position', block_pos);
    

    % Inputs

    blk_inputs = nodes.(node).inputs;
    [x2, y2] = Lus2SLXUtils.process_inputs(node_block_path, blk_inputs, node_name, x2, y2);
    
    % Outputs

    blk_outputs = nodes.(node).outputs;
    if isfield(nodes.(node), 'contract') ...
            && strcmp(nodes.(node).contract, 'true')
        isContract = true;
        [x2, y2] = Lus2SLXUtils.process_inputs(node_block_path, blk_outputs, node_name, x2, y2);
    else
        isContract = false;
        [x2, y2] = Lus2SLXUtils.process_outputs(node_block_path, blk_outputs, node_name, x2, y2);
    end

    % Instructions
    %deal with the invariant expressions for the cocospec Subsys,
    blk_exprs = nodes.(node).instrs;
    Lus2SLXUtils.instrs_process(nodes, new_model_name, node_block_path, blk_exprs, node_name, x2, y2, xml_trace);

    
    if isContract 
        blk_spec = nodes.(node).spec;
        Lus2SLXUtils.specInstrs_process(node_block_path, blk_spec, node_name);
    end
end
