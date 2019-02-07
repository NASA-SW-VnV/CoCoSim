function contract = construct_contact(node_struct, node_name)
    %inputs
    node_inputs = node_struct.inputs;
    nb_in = numel(node_inputs);
    inputs = cell(nb_in,1);
    for i=1:nb_in
        inputs{i} = node_inputs(i).name;
    end
    inputs = strjoin(inputs, ',');

    %outputs
    node_outputs = node_struct.outputs;
    nb_out = numel(node_outputs);
    outputs = cell(nb_out,1);
    for i=1:nb_out
        outputs{i} = node_outputs(i).name;
    end
    outputs = ['(' strjoin(outputs, ',') ')'];

    header = '(*@contract\nguarantee';

    functions_call_fmt =  '%s = %s(%s);';
    functions_call = sprintf(functions_call_fmt,...
        outputs, node_name, inputs);

    contract = sprintf('%s\t%s\n*)',...
        header, functions_call);
end

