%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function verif_node = construct_verif_node(...
        node_struct, node_name, new_node_name)
    %inputs
    node_inputs = node_struct.inputs;
    nb_in = numel(node_inputs);
    inputs_with_type = cell(nb_in,1);
    inputs = cell(nb_in,1);
    for i=1:nb_in
        dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(node_inputs(i).datatype);
        inputs_with_type{i} = sprintf('%s: %s',node_inputs(i).name, dt);
        inputs{i} = node_inputs(i).name;
    end
    inputs_with_type = strjoin(inputs_with_type, ';');
    inputs = strjoin(inputs, ',');

    %outputs
    node_outputs = node_struct.outputs;
    nb_out = numel(node_outputs);
    vars_type = cell(nb_out,1);
    outputs_1 = cell(nb_out,1);
    outputs_2 = cell(nb_out,1);

    for i=1:nb_out
        dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(node_outputs(i).datatype);
        vars_type{i} = sprintf('%s_1, %s_2: %s;',node_outputs(i).name, ...
            node_outputs(i).name, dt);
        outputs_1{i} = strcat(node_outputs(i).name, '_1');
        outputs_2{i} = strcat(node_outputs(i).name, '_2');
        ok_exp{i} = sprintf('%s = %s',outputs_1{i}, outputs_2{i});
    end
    vars_type = strjoin(vars_type, '\n');
    outputs_1 = ['(' strjoin(outputs_1, ',') ')'];
    outputs_2 = ['(' strjoin(outputs_2, ',') ')'];
    ok_exp = strjoin(ok_exp, ' and ');

    outputs = 'OK:bool';
    header_format = 'node top_verif(%s)\nreturns(%s);\nvar %s\nlet\n';
    header = sprintf(header_format,inputs_with_type, outputs, vars_type);

    functions_call_fmt =  '%s = %s(%s);\n%s = %s(%s);\n';
    functions_call = sprintf(functions_call_fmt,...
        outputs_1, node_name, inputs, outputs_2, new_node_name, inputs);

    Ok_def = sprintf('OK = %s;\n', ok_exp);

    Prop = '--%%PROPERTY  OK=true;';

    verif_node = sprintf('%s\n%s\n%s\n%s\ntel',...
        header, functions_call, Ok_def, Prop);

end
