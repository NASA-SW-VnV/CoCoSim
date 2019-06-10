%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function node_process(new_model_name, nodes, node, node_block_path, block_pos, xml_trace)
    node_name = BUtils.adapt_block_name(node);
    display_msg(...
        sprintf('Processing node "%s" ',node_name),...
        MsgType.INFO, 'lus2slx', '');
    x2 = 200;
    y2= -50;

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
