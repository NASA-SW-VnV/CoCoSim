%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
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
